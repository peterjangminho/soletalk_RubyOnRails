require "test_helper"

class SubscriptionFlowTest < ActionDispatch::IntegrationTest
  class FakeSyncService
    cattr_accessor :calls

    self.calls = []

    def call(user:)
      self.class.calls << user.id
      user.update!(
        subscription_status: "premium",
        subscription_tier: "premium",
        subscription_expires_at: 3.days.from_now
      )
      { success: true, premium: true }
    end
  end

  def sign_in(google_sub:, status: "free")
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: google_sub,
      info: {
        email: "#{google_sub}@example.com",
        name: "Subscription User"
      }
    )

    get "/auth/google_oauth2/callback"
    follow_redirect!
    User.find_by!(google_sub: google_sub).update!(subscription_status: status, subscription_tier: status)
  end

  test "P35-T1 GET /subscription renders paywall UI" do
    sign_in(google_sub: "sub-paywall-user", status: "free")

    get "/subscription"

    assert_response :ok
    assert_includes response.body, "Upgrade to Premium"
    assert_includes response.body, "Validate Subscription"
  end

  test "P35-T2 POST /subscription/validate performs server-side sync and updates user" do
    sign_in(google_sub: "sub-validate-user", status: "free")
    user = User.find_by!(google_sub: "sub-validate-user")
    original = SubscriptionController.subscription_sync_service_class
    SubscriptionController.subscription_sync_service_class = FakeSyncService
    FakeSyncService.calls = []

    post "/subscription/validate", params: { revenue_cat_id: "rc_paywall_1" }

    assert_redirected_to "/subscription"
    user.reload
    assert_equal "rc_paywall_1", user.revenue_cat_id
    assert_equal "premium", user.subscription_status
    assert_equal [ user.id ], FakeSyncService.calls
  ensure
    SubscriptionController.subscription_sync_service_class = original if original
  end

  test "P35-T3 premium users see manage-subscription state on paywall page" do
    sign_in(google_sub: "sub-premium-user", status: "premium")
    user = User.find_by!(google_sub: "sub-premium-user")
    user.update!(subscription_expires_at: 3.days.from_now)

    get "/subscription"

    assert_response :ok
    assert_includes response.body, "Manage Subscription"
    assert_not_includes response.body, "Upgrade to Premium"
  end
end
