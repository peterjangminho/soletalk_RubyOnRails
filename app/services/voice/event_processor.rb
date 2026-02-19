module Voice
  class EventProcessor
    LATITUDE_RANGE = -90.0..90.0
    LONGITUDE_RANGE = -180.0..180.0

    def call(message:, session_record: nil)
      return { success: false, error: "invalid_message" } unless message.valid?

      session_record ||= Session.find_by(id: message.session_id)
      return { success: false, error: "session_not_found" } unless session_record

      case message.action
      when "transcription"
        process_transcription(message, session_record)
      when "start_recording"
        process_start_recording(session_record)
      when "stop_recording"
        process_stop_recording(session_record)
      when "location_update"
        process_location_update(message, session_record)
      else
        { success: true }
      end
    end

    private

    def process_transcription(message, session_record)
      text = message.payload["text"].to_s
      return { success: false, error: "empty_transcription" } if text.blank?

      session_record.messages.create!(role: "user", content: text)
      { success: true }
    end

    def process_start_recording(session_record)
      voice_chat_data = ensure_voice_chat_data(session_record)
      metadata = voice_chat_data.metadata.to_h
      metadata["recording_active"] = true
      metadata["recording_started_at"] = Time.current.iso8601
      voice_chat_data.update!(metadata: metadata)
      { success: true }
    end

    def process_stop_recording(session_record)
      voice_chat_data = ensure_voice_chat_data(session_record)
      metadata = voice_chat_data.metadata.to_h
      metadata["recording_active"] = false
      metadata["recording_stopped_at"] = Time.current.iso8601
      voice_chat_data.update!(metadata: metadata)
      { success: true }
    end

    def process_location_update(message, session_record)
      latitude = float_value(message.payload["latitude"])
      longitude = float_value(message.payload["longitude"])
      return { success: false, error: "invalid_location_payload" } unless valid_coordinates?(latitude, longitude)

      voice_chat_data = ensure_voice_chat_data(session_record)
      metadata = voice_chat_data.metadata.to_h
      metadata["last_location"] = {
        "latitude" => latitude,
        "longitude" => longitude,
        "weather" => message.payload["weather"].to_s,
        "updated_at" => Time.current.iso8601
      }
      voice_chat_data.update!(metadata: metadata)
      { success: true }
    end

    def ensure_voice_chat_data(session_record)
      session_record.voice_chat_data || VoiceChatData.create!(session: session_record, current_phase: "opener")
    end

    def float_value(value)
      return nil if value.nil? || value.to_s.strip.empty?

      Float(value)
    rescue ArgumentError, TypeError # intentionally returns nil for invalid numeric input
      nil
    end

    def valid_coordinates?(latitude, longitude)
      return false if latitude.nil? || longitude.nil?

      LATITUDE_RANGE.cover?(latitude) && LONGITUDE_RANGE.cover?(longitude)
    end
  end
end
