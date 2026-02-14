module Auth
  class GoogleIdTokenVerifier
    TOKENINFO_URL = "https://oauth2.googleapis.com/tokeninfo".freeze
    VALID_ISSUERS = [ "accounts.google.com", "https://accounts.google.com" ].freeze

    def initialize(http_client: Faraday.new(url: TOKENINFO_URL))
      @http_client = http_client
    end

    def call(id_token:)
      return failure("id_token is required") if id_token.to_s.strip.blank?
      return failure("google_client_id_not_configured") if google_client_id.blank?

      response = @http_client.get("", { id_token: id_token })
      return failure("invalid_id_token") unless response.status == 200

      claims = JSON.parse(response.body)
      return failure("invalid_audience") unless claims["aud"] == google_client_id
      return failure("invalid_issuer") unless VALID_ISSUERS.include?(claims["iss"])
      return failure("google_sub_missing") if claims["sub"].to_s.strip.blank?

      {
        success: true,
        sub: claims["sub"],
        email: claims["email"],
        name: claims["name"],
        picture: claims["picture"]
      }
    rescue Faraday::Error, JSON::ParserError
      failure("invalid_id_token")
    end

    private

    def google_client_id
      ENV["GOOGLE_CLIENT_ID"]
    end

    def failure(error)
      { success: false, error: error }
    end
  end
end
