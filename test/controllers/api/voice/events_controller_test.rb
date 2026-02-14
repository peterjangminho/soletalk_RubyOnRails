require "test_helper"

module Api
  module Voice
    class EventsControllerTest < ActionDispatch::IntegrationTest
      class FakeProcessor
        cattr_accessor :last_message

        def call(message:)
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
          payload: { text: "transcribed speech" }
        }, as: :json

        assert_response :ok
        assert_equal "transcription", FakeProcessor.last_message.action
      ensure
        ::Api::Voice::EventsController.processor_class = original if original
      end
    end
  end
end
