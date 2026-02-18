module Auth
  class MobileSessionHandoffToken
    EXP_CLAIM = "exp".freeze
    GOOGLE_SUB_CLAIM = "google_sub".freeze
    USER_ID_CLAIM = "user_id".freeze

    class << self
      def generate(user_id:, google_sub:, expires_in: 2.minutes)
        payload = {
          USER_ID_CLAIM => user_id.to_s,
          GOOGLE_SUB_CLAIM => google_sub.to_s,
          EXP_CLAIM => (Time.current + expires_in).to_i
        }
        verifier.generate(payload)
      end

      def verify(token:)
        payload = verifier.verify(token.to_s)
        return nil if payload[EXP_CLAIM].to_i <= Time.current.to_i

        {
          user_id: payload[USER_ID_CLAIM].to_s,
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
