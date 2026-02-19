require "test_helper"

module Auth
  class OmniauthCallbacksControllerTest < ActionDispatch::IntegrationTest
    include ActiveJob::TestHelper

    def sign_in(google_sub:)
      OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
        provider: "google_oauth2", uid: google_sub,
        info: { email: "#{google_sub}@example.com", name: "Test User" }
      )
      get "/auth/google_oauth2/callback"
      follow_redirect!
    end

    test "GET /auth/google_oauth2/callback creates user and redirects to root" do
      OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
        provider: "google_oauth2",
        uid: "cb-new-user-1",
        info: { email: "cb-new@example.com", name: "New User" }
      )

      assert_difference "User.count", 1 do
        get "/auth/google_oauth2/callback"
      end

      assert_redirected_to "/"

      user = User.find_by!(google_sub: "cb-new-user-1")
      assert_equal "cb-new@example.com", user.email
      assert_equal "New User", user.name

      follow_redirect!
      get "/api/protected"
      assert_response :ok
    end

    test "GET /auth/google_oauth2/callback with existing user updates and signs in" do
      existing = User.create!(
        google_sub: "cb-existing-1",
        email: "old@example.com",
        name: "Old Name"
      )

      OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
        provider: "google_oauth2",
        uid: "cb-existing-1",
        info: { email: "updated@example.com", name: "Updated Name" }
      )

      assert_no_difference "User.count" do
        get "/auth/google_oauth2/callback"
      end

      assert_redirected_to "/"

      existing.reload
      assert_equal "updated@example.com", existing.email
      assert_equal "Updated Name", existing.name

      follow_redirect!
      get "/api/protected"
      assert_response :ok
    end

    test "GET /auth/failure redirects to root with alert" do
      get "/auth/failure"

      assert_redirected_to "/"
      follow_redirect!
      assert_match(/failed/i, flash[:alert]) if flash[:alert].present?
    end
  end
end
