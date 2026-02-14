require "test_helper"

module Auth
  class GoogleIdTokenVerifierTest < ActiveSupport::TestCase
    setup do
      @previous_google_client_id = ENV["GOOGLE_CLIENT_ID"]
    end

    teardown do
      ENV["GOOGLE_CLIENT_ID"] = @previous_google_client_id
    end

    test "P59-T4 returns claims when tokeninfo is valid" do
      ENV["GOOGLE_CLIENT_ID"] = "client-id-1"
      stub_request(:get, "https://oauth2.googleapis.com/tokeninfo")
        .with(query: { "id_token" => "good-token" })
        .to_return(
          status: 200,
          body: {
            aud: "client-id-1",
            iss: "https://accounts.google.com",
            sub: "native-sub-1",
            email: "native@example.com",
            name: "Native User",
            picture: "https://example.com/p.png"
          }.to_json
        )

      result = Auth::GoogleIdTokenVerifier.new.call(id_token: "good-token")

      assert_equal true, result[:success]
      assert_equal "native-sub-1", result[:sub]
      assert_equal "native@example.com", result[:email]
    end

    test "P59-T5 rejects mismatched audience" do
      ENV["GOOGLE_CLIENT_ID"] = "client-id-1"
      stub_request(:get, "https://oauth2.googleapis.com/tokeninfo")
        .with(query: { "id_token" => "bad-aud-token" })
        .to_return(
          status: 200,
          body: {
            aud: "other-client",
            iss: "https://accounts.google.com",
            sub: "native-sub-2"
          }.to_json
        )

      result = Auth::GoogleIdTokenVerifier.new.call(id_token: "bad-aud-token")

      assert_equal false, result[:success]
      assert_equal "invalid_audience", result[:error]
    end

    test "P59-T6 returns configuration error when GOOGLE_CLIENT_ID is missing" do
      ENV.delete("GOOGLE_CLIENT_ID")

      result = Auth::GoogleIdTokenVerifier.new.call(id_token: "any-token")

      assert_equal false, result[:success]
      assert_equal "google_client_id_not_configured", result[:error]
    end
  end
end
