require "test_helper"

module Admin
  class JobsControllerTest < ActionDispatch::IntegrationTest
    include ActiveJob::TestHelper

    def sign_in(google_sub:)
      OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
        provider: "google_oauth2", uid: google_sub,
        info: { email: "#{google_sub}@example.com", name: "Test User" }
      )
      get "/auth/google_oauth2/callback"
      follow_redirect!
    end

    test "GET /admin/jobs redirects unauthenticated users" do
      get "/admin/jobs"

      assert_response :redirect
      assert_redirected_to "/"
    end

    test "GET /admin/jobs shows dashboard for signed-in user" do
      sign_in(google_sub: "g-admin-jobs")

      get "/admin/jobs"

      assert_response :ok
    end
  end
end
