require "test_helper"

class AdminJobsDashboardFlowTest < ActionDispatch::IntegrationTest
  def sign_in(google_sub:)
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: google_sub,
      info: {
        email: "#{google_sub}@example.com",
        name: "Admin User"
      }
    )

    get "/auth/google_oauth2/callback"
    follow_redirect!
  end

  test "P31-T3 admin job dashboard exposes failed/dead-letter summary" do
    sign_in(google_sub: "admin-jobs-user")

    get "/admin/jobs"

    assert_response :ok
    assert_includes response.body, "Job Dashboard"
    assert_includes response.body, "Failed Executions"
    assert_includes response.body, "Dead Letters"
  end
end
