require "test_helper"

module Api
  class ProtectedControllerTest < ActionDispatch::IntegrationTest
    def sign_in(google_sub:)
      OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
        provider: "google_oauth2", uid: google_sub,
        info: { email: "#{google_sub}@example.com", name: "Test User" }
      )
      get "/auth/google_oauth2/callback"
      follow_redirect!
    end

    test "GET /api/protected redirects unauthenticated" do
      get "/api/protected"

      assert_response :redirect
      assert_redirected_to "/"
    end

    test "GET /api/protected returns user info when signed in" do
      sign_in(google_sub: "api-protected-user")

      get "/api/protected"

      assert_response :ok
      body = JSON.parse(response.body)
      assert_equal true, body["success"]

      user = User.find_by!(google_sub: "api-protected-user")
      assert_equal user.id, body["user_id"]
    end
  end
end
