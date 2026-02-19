require "test_helper"

class SubscriptionControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  class FakeConfigErrorService
    def initialize
      raise Subscription::RevenueCatClient::ConfigurationError, "Missing REVENUECAT_BASE_URL"
    end
  end

  def sign_in(google_sub:)
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2", uid: google_sub,
      info: { email: "#{google_sub}@example.com", name: "Test User" }
    )
    get "/auth/google_oauth2/callback"
    follow_redirect!
  end

  test "GET /subscription redirects unauthenticated users" do
    get "/subscription"

    assert_response :redirect
    assert_redirected_to "/"
  end

  test "GET /subscription redirects to settings for signed-in user" do
    sign_in(google_sub: "g-sub-show")

    get "/subscription"

    assert_redirected_to "/setting#subscription"
  end

  test "POST /subscription/validate redirects unauthenticated users" do
    post "/subscription/validate", params: { revenue_cat_id: "rc_test" }

    assert_response :redirect
    assert_redirected_to "/"
  end

  test "POST /subscription/validate with configuration error shows alert" do
    sign_in(google_sub: "g-sub-config-err")
    original = SubscriptionController.subscription_sync_service_class
    SubscriptionController.subscription_sync_service_class = FakeConfigErrorService

    post "/subscription/validate", params: { revenue_cat_id: "rc_anything" }

    assert_redirected_to "/setting#subscription"
    follow_redirect!
    assert_response :ok
  ensure
    SubscriptionController.subscription_sync_service_class = original
  end
end
