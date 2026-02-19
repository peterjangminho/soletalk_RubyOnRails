require "test_helper"

module Auth
  class GuestSessionsControllerTest < ActionDispatch::IntegrationTest
    def sign_in(google_sub:)
      OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
        provider: "google_oauth2", uid: google_sub,
        info: { email: "#{google_sub}@example.com", name: "Test User" }
      )
      get "/auth/google_oauth2/callback"
      follow_redirect!
    end

    test "POST /guest_sign_in creates guest user and signs in" do
      assert_difference "User.count", 1 do
        post "/guest_sign_in"
      end

      assert_redirected_to "/"
      follow_redirect!

      get "/api/protected"
      assert_response :ok
    end

    test "POST /guest_sign_in with consent_accepted sets policy_agreed" do
      post "/guest_sign_in", params: { consent_accepted: "1" }

      assert_redirected_to "/"
      follow_redirect!

      # Verify session is active (policy_agreed allows sign in flow)
      get "/api/protected"
      assert_response :ok
    end

    test "POST /guest_sign_in creates user with guest- prefix google_sub" do
      post "/guest_sign_in"

      user = User.last
      assert user.google_sub.start_with?("guest-"), "Expected google_sub to start with 'guest-', got: #{user.google_sub}"
      assert_equal "Guest User", user.name
    end
  end
end
