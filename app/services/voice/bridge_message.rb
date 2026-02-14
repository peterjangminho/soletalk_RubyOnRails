module Voice
  class BridgeMessage
    ALLOWED_ACTIONS = %w[start_recording stop_recording transcription location_update].freeze

    attr_reader :action, :session_id, :payload

    def initialize(action:, session_id:, payload:)
      @action = action.to_s
      @session_id = session_id.to_s
      @payload = payload || {}
    end

    def valid?
      ALLOWED_ACTIONS.include?(action) && session_id.present?
    end
  end
end
