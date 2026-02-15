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

  class FakeMissingIdService
    cattr_accessor :calls

    self.calls = []

    def call(user:)
      self.class.calls << user.id
      { success: false, error: "revenue_cat_id_missing" }
    end
  end

  class FakeMisconfiguredService
    def initialize
      raise Subscription::RevenueCatClient::ConfigurationError, "Missing REVENUECAT_BASE_URL"
    end
  end

  def with_forgery_protection
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    yield
  ensure
    ActionController::Base.allow_forgery_protection = original
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
    assert_includes response.body, "Choose Your Plan"
    assert_includes response.body, "Restore Subscription"
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

  test "P71-T1 free subscription page shows plan guidance and restore section" do
    sign_in(google_sub: "sub-upgrade-guide-user", status: "free")

    get "/subscription"

    assert_response :ok
    assert_includes response.body, "Choose Your Plan"
    assert_includes response.body, "Already subscribed?"
    assert_includes response.body, "Restore Subscription"
  end

  test "P71-T2 validate shows alert when revenue cat id is missing" do
    sign_in(google_sub: "sub-missing-id-user", status: "free")
    original = SubscriptionController.subscription_sync_service_class
    SubscriptionController.subscription_sync_service_class = FakeMissingIdService
    FakeMissingIdService.calls = []

    post "/subscription/validate", params: { revenue_cat_id: "  " }

    assert_redirected_to "/subscription"
    follow_redirect!
    assert_includes response.body, "RevenueCat Customer ID is required"
    assert_equal 1, FakeMissingIdService.calls.size
  ensure
    SubscriptionController.subscription_sync_service_class = original if original
  end

  test "P71-T3 validate reuses saved revenue cat id when input is blank" do
    sign_in(google_sub: "sub-saved-id-user", status: "free")
    user = User.find_by!(google_sub: "sub-saved-id-user")
    user.update!(revenue_cat_id: "rc_existing_1")
    original = SubscriptionController.subscription_sync_service_class
    SubscriptionController.subscription_sync_service_class = FakeSyncService
    FakeSyncService.calls = []

    post "/subscription/validate", params: { revenue_cat_id: " " }

    assert_redirected_to "/subscription"
    user.reload
    assert_equal "rc_existing_1", user.revenue_cat_id
    assert_equal [ user.id ], FakeSyncService.calls
  ensure
    SubscriptionController.subscription_sync_service_class = original if original
  end

  test "P74-T1 validate handles revenuecat configuration error without 500" do
    sign_in(google_sub: "sub-config-error-user", status: "free")
    original = SubscriptionController.subscription_sync_service_class
    SubscriptionController.subscription_sync_service_class = FakeMisconfiguredService

    post "/subscription/validate", params: { revenue_cat_id: "rc_anything" }

    assert_redirected_to "/subscription"
    follow_redirect!
    assert_response :ok
    assert_includes response.body, "Subscription service is not configured"
  ensure
    SubscriptionController.subscription_sync_service_class = original if original
  end

  test "P74-T3 validate with invalid csrf does not surface 500 page" do
    with_forgery_protection do
      post "/subscription/validate", params: { revenue_cat_id: "rc_anything" }

      assert_response :unprocessable_entity
      assert_includes response.body, "invalid authenticity token"
    end
  end
end
