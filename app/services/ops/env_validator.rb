module Ops
  class EnvValidator
    REQUIRED_KEYS = %w[
      ONTOLOGY_RAG_BASE_URL
      ONTOLOGY_RAG_API_KEY
      GOOGLE_CLIENT_ID
      GOOGLE_CLIENT_SECRET
      SECRET_KEY_BASE
    ].freeze

    def initialize(env: ENV.to_h)
      @env = env
    end

    def validate
      missing = REQUIRED_KEYS.select { |key| @env[key].blank? }
      {
        ok: missing.empty?,
        missing: missing
      }
    end
  end
end
