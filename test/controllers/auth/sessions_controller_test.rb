require "test_helper"

module Auth
  class SessionsControllerTest < ActionDispatch::IntegrationTest
    def sign_in(google_sub:)
      OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
        provider: "google_oauth2", uid: google_sub,
        info: { email: "#{google_sub}@example.com", name: "Test User" }
      )
      get "/auth/google_oauth2/callback"
      follow_redirect!
    end

    test "DELETE /sign_out clears session and redirects" do
      sign_in(google_sub: "g-signout-1")

      delete "/sign_out"

      assert_redirected_to "/"
      follow_redirect!

      # Session should be cleared; protected endpoint should deny access
      get "/api/protected"
      assert_response :redirect
    end

    test "DELETE /sign_out when not signed in still redirects" do
      delete "/sign_out"

      assert_redirected_to "/"
      follow_redirect!
      assert_response :ok
    end
  end
end
