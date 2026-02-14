module VoiceChat
  class ContextOrchestrator
    PROFILE_TTL = 30.minutes
    PAST_MEMORY_TTL = 5.minutes
    ADDITIONAL_INFO_TTL = 1.hour

    def initialize(cache_store: Rails.cache, ontology_client: nil)
      @cache_store = cache_store
      @ontology_client = ontology_client
    end

    def build(profile:, past_memory:, current_session:, additional_info:, ai_persona:, google_sub: nil, session_id: nil)
      {
        profile: fetch_cache(layer: :profile, google_sub: google_sub, session_id: session_id, ttl: PROFILE_TTL) { profile },
        past_memory: fetch_cache(layer: :past_memory, google_sub: google_sub, session_id: session_id, ttl: PAST_MEMORY_TTL) { past_memory },
        current_session: current_session,
        additional_info: fetch_cache(layer: :additional_info, google_sub: google_sub, session_id: session_id, ttl: ADDITIONAL_INFO_TTL) { additional_info },
        ai_persona: fetch_cache(layer: :ai_persona, google_sub: google_sub, session_id: session_id, ttl: nil) { ai_persona }
      }
    end

    def build_dynamic(google_sub:, session_id:, current_session:, ai_persona:, additional_query: nil)
      profile = fetch_profile(google_sub: google_sub)
      past_memory = fetch_past_memory(google_sub: google_sub)
      additional_info = fetch_additional_info(google_sub: google_sub, additional_query: additional_query)

      build(
        google_sub: google_sub,
        session_id: session_id,
        profile: profile,
        past_memory: past_memory,
        current_session: current_session,
        additional_info: additional_info,
        ai_persona: ai_persona
      )
    end

    private

    def fetch_cache(layer:, google_sub:, session_id:, ttl:)
      return yield unless @cache_store

      options = ttl ? { expires_in: ttl } : {}
      @cache_store.fetch(cache_key(layer: layer, google_sub: google_sub, session_id: session_id), **options) { yield }
    end

    def cache_key(layer:, google_sub:, session_id:)
      scope =
        case layer
        when :profile, :past_memory
          google_sub.presence || "anonymous"
        when :additional_info
          session_id.presence || "session-unknown"
        when :ai_persona
          "global"
        end

      "voice_chat:context:#{layer}:#{scope}"
    end

    def fetch_profile(google_sub:)
      response = ontology_client.get_cached_profile(google_sub: google_sub)
      response[:profile] || {}
    end

    def fetch_past_memory(google_sub:)
      ontology_client.query(question: "recent memory context", google_sub: google_sub, limit: 3)
    end

    def fetch_additional_info(google_sub:, additional_query:)
      return {} if additional_query.blank?

      ontology_client.query(question: additional_query, google_sub: google_sub, limit: 3)
    end

    def ontology_client
      @ontology_client ||= OntologyRag::Client.new
    end
  end
end
