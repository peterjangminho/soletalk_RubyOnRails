module Voice
  class EventProcessor
    def call(message:)
      return { success: false, error: "invalid_message" } unless message.valid?

      case message.action
      when "transcription"
        process_transcription(message)
      else
        { success: true }
      end
    end

    private

    def process_transcription(message)
      session_record = Session.find(message.session_id)
      text = message.payload["text"].to_s
      return { success: false, error: "empty_transcription" } if text.blank?

      session_record.messages.create!(role: "user", content: text)
      { success: true }
    end
  end
end
