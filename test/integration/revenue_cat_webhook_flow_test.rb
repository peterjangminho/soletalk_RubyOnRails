require "test_helper"

class RevenueCatWebhookFlowTest < ActionDispatch::IntegrationTest
  test "P32-T3 RevenueCat webhook updates user subscription state" do
    user = User.create!(google_sub: "g-webhook-user", subscription_status: "free")

    post "/webhooks/revenue_cat", params: {
      event_type: "INITIAL_PURCHASE",
      google_sub: user.google_sub,
      revenue_cat_id: "rc_123",
      expires_at: 2.days.from_now.iso8601
    }, as: :json

    assert_response :ok
    user.reload

    assert_equal "premium", user.subscription_status
    assert_equal "premium", user.subscription_tier
    assert_equal "rc_123", user.revenue_cat_id
    assert_equal true, user.subscription_expires_at.future?

    post "/webhooks/revenue_cat", params: {
      event_type: "EXPIRATION",
      google_sub: user.google_sub
    }, as: :json

    assert_response :ok
    user.reload

    assert_equal "free", user.subscription_status
    assert_equal "free", user.subscription_tier
    assert_nil user.subscription_expires_at
  end
end
