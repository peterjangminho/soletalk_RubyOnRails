module Auth
  class VoiceBridgeToken
    EXP_CLAIM = "exp".freeze
    GOOGLE_SUB_CLAIM = "google_sub".freeze
    SESSION_ID_CLAIM = "session_id".freeze

    class << self
      def generate(session_id:, google_sub:, expires_in: 15.minutes)
        payload = {
          SESSION_ID_CLAIM => session_id.to_s,
          GOOGLE_SUB_CLAIM => google_sub.to_s,
          EXP_CLAIM => (Time.current + expires_in).to_i
        }
        verifier.generate(payload)
      end

      def verify(token:)
        payload = verifier.verify(token.to_s)
        return nil if payload[EXP_CLAIM].to_i <= Time.current.to_i

        {
          session_id: payload[SESSION_ID_CLAIM].to_s,
          google_sub: payload[GOOGLE_SUB_CLAIM].to_s,
          exp: payload[EXP_CLAIM].to_i
        }
      rescue StandardError
        nil
      end

      private

      def verifier
        @verifier ||= ActiveSupport::MessageVerifier.new(
          Rails.application.secret_key_base,
          digest: "SHA256",
          serializer: JSON
        )
      end
    end
  end
end
