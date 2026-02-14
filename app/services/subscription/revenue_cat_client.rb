require "faraday"
require "json"

module Subscription
  class RevenueCatClient
    class ConfigurationError < StandardError; end

    PREMIUM_ENTITLEMENT = "premium_access".freeze

    def initialize(
      base_url: ENV.fetch("REVENUECAT_BASE_URL", nil),
      api_key: ENV.fetch("REVENUECAT_API_KEY", nil),
      http_adapter: nil,
      open_timeout: 5,
      read_timeout: 10
    )
      raise ConfigurationError, "Missing REVENUECAT_BASE_URL" if base_url.blank?
      raise ConfigurationError, "Missing REVENUECAT_API_KEY" if api_key.blank?

      @base_url = base_url
      @api_key = api_key
      @http_adapter = http_adapter
      @open_timeout = open_timeout
      @read_timeout = read_timeout
    end

    def fetch_subscriber(revenue_cat_id:)
      raw = adapter.call(
        path: "/v1/subscribers/#{revenue_cat_id}",
        method: :get,
        headers: default_headers,
        body: nil,
        params: nil,
        open_timeout: @open_timeout,
        read_timeout: @read_timeout
      )

      payload = raw["payload"] || raw
      entitlement = payload.dig("subscriber", "entitlements", PREMIUM_ENTITLEMENT) || {}
      expires_at = parse_time(entitlement["expires_date"])

      {
        premium: expires_at.present? && expires_at > Time.current,
        expires_at: expires_at,
        raw: raw
      }
    end

    private

    def default_headers
      {
        "Authorization" => "Bearer #{@api_key}",
        "Content-Type" => "application/json"
      }
    end

    def adapter
      @http_adapter || method(:default_http_adapter)
    end

    def default_http_adapter(path:, method:, headers:, body:, params:, open_timeout:, read_timeout:)
      response = connection(open_timeout: open_timeout, read_timeout: read_timeout).run_request(method, path, body, headers) do |request|
        request.params.update(params) if params.present?
      end
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

    def parse_time(value)
      return nil if value.blank?

      Time.zone.parse(value)
    end
  end
end
