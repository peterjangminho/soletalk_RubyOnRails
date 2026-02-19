require "test_helper"

module Webhooks
  class RevenueCatControllerTest < ActionDispatch::IntegrationTest
    def sign_in(google_sub:)
      OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
        provider: "google_oauth2", uid: google_sub,
        info: { email: "#{google_sub}@example.com", name: "Test User" }
      )
      get "/auth/google_oauth2/callback"
      follow_redirect!
    end

    test "POST /webhooks/revenue_cat with INITIAL_PURCHASE sets premium" do
      user = User.create!(google_sub: "rc-purchase-user", email: "rc@example.com", name: "RC User")
      expires = 30.days.from_now.iso8601

      post "/webhooks/revenue_cat", params: {
        google_sub: user.google_sub,
        event_type: "INITIAL_PURCHASE",
        expires_at: expires,
        revenue_cat_id: "rc_id_123"
      }, as: :json

      assert_response :ok
      body = JSON.parse(response.body)
      assert_equal true, body["success"]

      user.reload
      assert_equal "premium", user.subscription_status
      assert_equal "premium", user.subscription_tier
      assert_equal "rc_id_123", user.revenue_cat_id
      assert_not_nil user.subscription_expires_at
    end

    test "POST /webhooks/revenue_cat with EXPIRATION sets free" do
      user = User.create!(
        google_sub: "rc-expire-user", email: "rc-expire@example.com", name: "RC Expire",
        subscription_status: "premium", subscription_tier: "premium",
        subscription_expires_at: 30.days.from_now
      )

      post "/webhooks/revenue_cat", params: {
        google_sub: user.google_sub,
        event_type: "EXPIRATION"
      }, as: :json

      assert_response :ok

      user.reload
      assert_equal "free", user.subscription_status
      assert_equal "free", user.subscription_tier
      assert_nil user.subscription_expires_at
    end

    test "POST /webhooks/revenue_cat with unknown user returns not_found" do
      post "/webhooks/revenue_cat", params: {
        google_sub: "nonexistent-user",
        event_type: "INITIAL_PURCHASE"
      }, as: :json

      assert_response :not_found
    end

    test "POST /webhooks/revenue_cat without event_type returns bad_request" do
      user = User.create!(google_sub: "rc-missing-param", email: "rc-mp@example.com", name: "RC MP")

      post "/webhooks/revenue_cat", params: {
        google_sub: user.google_sub
      }, as: :json

      assert_response :bad_request
    end
  end
end
