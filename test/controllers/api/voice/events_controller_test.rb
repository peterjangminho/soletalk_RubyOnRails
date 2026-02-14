require "test_helper"

module Api
  module Voice
    class EventsControllerTest < ActionDispatch::IntegrationTest
      class FakeProcessor
        cattr_accessor :last_message

        def call(message:, session_record: nil)
          self.class.last_message = message
          { success: true }
        end
      end

      test "P36-T2 POST /api/voice/events processes transcription into session messages" do
        user = User.create!(google_sub: "g-voice-event")
        session_record = Session.create!(user: user, status: "active")
        original = ::Api::Voice::EventsController.processor_class
        ::Api::Voice::EventsController.processor_class = FakeProcessor
        FakeProcessor.last_message = nil

        post "/api/voice/events", params: {
          event_action: "transcription",
          session_id: session_record.id,
          google_sub: user.google_sub,
          payload: { text: "transcribed speech" }
        }, as: :json

        assert_response :ok
        assert_equal "transcription", FakeProcessor.last_message.action
      ensure
        ::Api::Voice::EventsController.processor_class = original if original
      end

      test "P55-T2 POST /api/voice/events rejects mismatched google_sub with forbidden" do
        user = User.create!(google_sub: "g-voice-owner")
        session_record = Session.create!(user: user, status: "active")

        post "/api/voice/events", params: {
          event_action: "transcription",
          session_id: session_record.id,
          google_sub: "different-sub",
          payload: { text: "transcribed speech" }
        }, as: :json

        assert_response :forbidden
        body = JSON.parse(response.body)
        assert_equal false, body["success"]
        assert_equal "forbidden", body["error"]
      end

      test "P61-T3 POST /api/voice/events allows request with valid bridge_token" do
        user = User.create!(google_sub: "g-voice-bridge-token")
        session_record = Session.create!(user: user, status: "active")
        bridge_token = ::Auth::VoiceBridgeToken.generate(
          session_id: session_record.id.to_s,
          google_sub: user.google_sub
        )

        original = ::Api::Voice::EventsController.processor_class
        ::Api::Voice::EventsController.processor_class = FakeProcessor
        FakeProcessor.last_message = nil

        post "/api/voice/events", params: {
          event_action: "transcription",
          session_id: session_record.id,
          payload: { text: "transcribed speech", bridge_token: bridge_token }
        }, as: :json

        assert_response :ok
        assert_equal "transcription", FakeProcessor.last_message.action
      ensure
        ::Api::Voice::EventsController.processor_class = original if original
      end
    end
  end
end
