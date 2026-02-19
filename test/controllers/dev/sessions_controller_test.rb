require "test_helper"

module Dev
  class SessionsControllerTest < ActionDispatch::IntegrationTest
    def sign_in(google_sub:)
      OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
        provider: "google_oauth2", uid: google_sub,
        info: { email: "#{google_sub}@example.com", name: "Test User" }
      )
      get "/auth/google_oauth2/callback"
      follow_redirect!
    end

    test "POST /dev/sign_in creates dev user and signs in" do
      assert_difference "User.count", 1 do
        post "/dev/sign_in"
      end

      user = User.find_by!(google_sub: "dev-mobile-user")
      assert_equal "Dev Mobile User", user.name
      assert_equal "dev-mobile-user@local.dev", user.email
      assert_redirected_to "/"
    end

    test "POST /dev/sign_in with custom google_sub creates correct user" do
      assert_difference "User.count", 1 do
        post "/dev/sign_in", params: { google_sub: "custom-dev-sub" }
      end

      user = User.find_by!(google_sub: "custom-dev-sub")
      assert_equal "Dev Mobile User", user.name
      assert_equal "custom-dev-sub@local.dev", user.email
      assert_redirected_to "/"
    end

    test "DELETE /dev/sign_out clears session and redirects" do
      post "/dev/sign_in"
      assert_redirected_to "/"

      delete "/dev/sign_out"

      assert_redirected_to "/"
      follow_redirect!

      # Verify session is cleared by checking that protected endpoint redirects
      get "/api/protected"
      assert_response :redirect
    end
  end
end
