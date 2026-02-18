require "test_helper"

class InsightAccessFlowTest < ActionDispatch::IntegrationTest
  def sign_in(google_sub:, status:)
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: google_sub,
      info: {
        email: "#{google_sub}@example.com",
        name: "Insight Access User"
      }
    )

    get "/auth/google_oauth2/callback"
    follow_redirect!

    User.find_by!(google_sub: google_sub).update!(
      subscription_status: status,
      subscription_tier: status == "premium" ? "premium" : "free",
      subscription_expires_at: status == "premium" ? 2.days.from_now : nil
    )
  end

  test "P33-T3 all users redirected from insights to root (voice-only IA)" do
    premium_google_sub = "insight-premium-user"
    sign_in(google_sub: premium_google_sub, status: "premium")

    get "/insights"
    assert_redirected_to "/"

    sign_in(google_sub: "insight-free-user", status: "free")
    get "/insights"
    assert_redirected_to "/"
  end
end
