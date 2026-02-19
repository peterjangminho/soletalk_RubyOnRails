require "test_helper"

module Auth
  class OauthStartsControllerTest < ActionDispatch::IntegrationTest
    def sign_in(google_sub:)
      OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
        provider: "google_oauth2", uid: google_sub,
        info: { email: "#{google_sub}@example.com", name: "Test User" }
      )
      get "/auth/google_oauth2/callback"
      follow_redirect!
    end

    test "GET /auth/google_oauth2/start without consent redirects to consent" do
      get "/auth/google_oauth2/start"

      assert_redirected_to "/consent"
    end

    test "GET /auth/google_oauth2/start with consent_accepted=1 redirects to oauth" do
      get "/auth/google_oauth2/start", params: { consent_accepted: "1" }

      assert_redirected_to "/auth/google_oauth2"
    end

    test "GET /auth/google_oauth2/start with session policy_agreed redirects to oauth" do
      post "/consent/accept", params: { agree: "1" }
      follow_redirect!

      get "/auth/google_oauth2/start"

      assert_redirected_to "/auth/google_oauth2"
    end
  end
end
