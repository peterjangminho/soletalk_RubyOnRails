require "test_helper"

module Voice
  class EventProcessorTest < ActiveSupport::TestCase
    test "P55-T1 start_recording updates voice_chat_data metadata" do
      user = User.create!(google_sub: "g-p55-start")
      session_record = Session.create!(user: user, status: "active")
      processor = Voice::EventProcessor.new

      result = processor.call(
        message: Voice::BridgeMessage.new(
          action: "start_recording",
          session_id: session_record.id,
          payload: {}
        )
      )

      assert_equal true, result[:success]
      assert_equal true, session_record.reload.voice_chat_data.metadata["recording_active"]
      assert_not_nil session_record.voice_chat_data.metadata["recording_started_at"]
    end

    test "P55-T1 stop_recording updates voice_chat_data metadata" do
      user = User.create!(google_sub: "g-p55-stop")
      session_record = Session.create!(user: user, status: "active")
      voice_chat_data = VoiceChatData.create!(session: session_record, current_phase: "opener")
      voice_chat_data.update!(metadata: { "recording_active" => true })
      processor = Voice::EventProcessor.new

      result = processor.call(
        message: Voice::BridgeMessage.new(
          action: "stop_recording",
          session_id: session_record.id,
          payload: {}
        )
      )

      assert_equal true, result[:success]
      assert_equal false, session_record.reload.voice_chat_data.metadata["recording_active"]
      assert_not_nil session_record.voice_chat_data.metadata["recording_stopped_at"]
    end

    test "P55-T1 location_update stores latitude longitude and weather in metadata" do
      user = User.create!(google_sub: "g-p55-location")
      session_record = Session.create!(user: user, status: "active")
      processor = Voice::EventProcessor.new

      result = processor.call(
        message: Voice::BridgeMessage.new(
          action: "location_update",
          session_id: session_record.id,
          payload: { "latitude" => 37.12, "longitude" => 127.45, "weather" => "rain" }
        )
      )

      assert_equal true, result[:success]
      location = session_record.reload.voice_chat_data.metadata["last_location"]
      assert_equal 37.12, location["latitude"]
      assert_equal 127.45, location["longitude"]
      assert_equal "rain", location["weather"]
      assert_not_nil location["updated_at"]
    end

    test "P55-T1 location_update rejects invalid payload" do
      user = User.create!(google_sub: "g-p55-invalid-location")
      session_record = Session.create!(user: user, status: "active")
      processor = Voice::EventProcessor.new

      result = processor.call(
        message: Voice::BridgeMessage.new(
          action: "location_update",
          session_id: session_record.id,
          payload: { "latitude" => "", "longitude" => nil }
        )
      )

      assert_equal false, result[:success]
      assert_equal "invalid_location_payload", result[:error]
    end
  end
end
