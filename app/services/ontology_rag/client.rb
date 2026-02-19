require "json"
require "faraday"

module OntologyRag
  class Client
    class ConfigurationError < StandardError; end

    RETRYABLE_ERRORS = [
      Timeout::Error,
      Faraday::TimeoutError,
      Faraday::ConnectionFailed,
      Net::OpenTimeout,
      Net::ReadTimeout,
      Errno::ETIMEDOUT
    ].freeze

    attr_reader :base_url

    def initialize(
      base_url: ENV.fetch("ONTOLOGY_RAG_BASE_URL", nil),
      api_key: ENV.fetch("ONTOLOGY_RAG_API_KEY", nil),
      http_adapter: nil,
      retry_attempts: Constants::TIMEOUTS[:retries],
      open_timeout: Constants::TIMEOUTS[:open],
      read_timeout: Constants::TIMEOUTS[:read],
      cache_store: Rails.cache,
      query_cache_ttl: 300
    )
      raise ConfigurationError, "Missing ONTOLOGY_RAG_BASE_URL" if base_url.blank?
      raise ConfigurationError, "Missing ONTOLOGY_RAG_API_KEY" if api_key.blank?

      @base_url = base_url
      @api_key = api_key
      @http_adapter = http_adapter
      @retry_attempts = retry_attempts
      @open_timeout = open_timeout
      @read_timeout = read_timeout
      @cache_store = cache_store
      @query_cache_ttl = query_cache_ttl
    end

    def default_headers
      {
        "X-API-Key" => @api_key,
        "X-Source-App" => Constants::SOURCE_APP,
        "X-Request-ID" => request_id,
        "Content-Type" => "application/json"
      }
    end

    def identify_user(google_sub:, external_user_id: nil, app_source: Constants::APP_SOURCE)
      payload = {
        google_sub: google_sub,
        app_source: app_source
      }
      payload[:external_user_id] = external_user_id if external_user_id.present?

      post(Constants::ENDPOINTS[:identify_user], payload)
    end

    def get_prompts(google_sub:, limit: nil)
      params = {}
      params[:limit] = limit if limit.present?

      get(format(Constants::ENDPOINTS[:get_profile], google_sub: google_sub), params: params)
    end

    def get_cached_profile(google_sub:)
      response = get(format(Constants::ENDPOINTS[:get_cached_profile], google_sub: google_sub), params: {})
      {
        google_sub: response["google_sub"],
        profile: response["profile"] || {}
      }
    end

    def query(question:, google_sub: nil, limit: 5, container_id: nil)
      cache_key = build_query_cache_key(question: question, google_sub: google_sub, limit: limit, container_id: container_id)
      @cache_store.fetch(cache_key, expires_in: @query_cache_ttl) do
        payload = {
          question: question,
          limit: limit
        }
        payload[:google_sub] = google_sub if google_sub.present?
        payload[:container_id] = container_id if container_id.present?

        response = post("/engine/query", payload)
        normalized = Models::QueryResponse.from_api(response)

        {
          answer: normalized.answer,
          context: normalized.context,
          sources: normalized.sources,
          query: normalized.query
        }
      end
    end

    def record_events(google_sub:, events:)
      post(Constants::ENDPOINTS[:batch_save_events], { google_sub: google_sub, events: events })
    end

    def save_conversation(session_id:, google_sub:, conversation:, metadata: {})
      payload = {
        google_sub: google_sub,
        conversation: conversation,
        metadata: metadata
      }

      post(format(Constants::ENDPOINTS[:save_conversation], session_id: session_id), payload)
    end

    def create_object(domain:, type:, properties:, google_sub:)
      payload = {
        domain: domain,
        type: type,
        properties: properties,
        google_sub: google_sub
      }

      post(Constants::ENDPOINTS[:create_object], payload)
    end

    def create_document(object_id:, content:, metadata: {}, auto_chunk: true)
      payload = {
        object_id: object_id,
        content: content,
        metadata: metadata,
        auto_chunk: auto_chunk
      }

      post(Constants::ENDPOINTS[:create_document], payload)
    end

    private

    def get(path, params: {})
      request_with_retry(path: path, method: :get, params: params)
    end

    def post(path, body)
      request_with_retry(path: path, method: :post, body: body)
    end

    def request_with_retry(path:, method:, body: nil, params: nil)
      retries = 0
      begin
        adapter.call(
          path: path,
          method: method,
          headers: default_headers,
          body: body,
          params: params,
          open_timeout: @open_timeout,
          read_timeout: @read_timeout
        )
      rescue *RETRYABLE_ERRORS => e
        retries += 1
        retry if retries <= @retry_attempts

        {
          "success" => false,
          "error" => e.class.name,
          "message" => e.message,
          "path" => path
        }
      end
    end

    def adapter
      @http_adapter || method(:default_http_adapter)
    end

    def default_http_adapter(path:, method:, headers:, body:, params:, open_timeout:, read_timeout:)
      response = connection(open_timeout: open_timeout, read_timeout: read_timeout).run_request(
        method,
        path,
        body,
        headers
      ) do |request|
        request.params.update(params) if params.present?
      end

      return {} if response.body.blank?

      response.body.is_a?(String) ? JSON.parse(response.body) : response.body
    end

    def connection(open_timeout:, read_timeout:)
      Faraday.new(url: @base_url) do |faraday|
        faraday.options.timeout = read_timeout
        faraday.options.open_timeout = open_timeout
        faraday.request :json
        faraday.response :json, content_type: /\bjson$/
        faraday.adapter Faraday.default_adapter
      end
    end

    def request_id
      "soletalk-#{SecureRandom.uuid}"
    end

    def build_query_cache_key(question:, google_sub:, limit:, container_id:)
      "ontology_rag:query:#{google_sub}:#{question}:#{limit}:#{container_id}"
    end
  end
end
