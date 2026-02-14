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

  test "P33-T3 blocks free users and allows premium users for insights" do
    insight = Insight.create!(
      situation: "gate situation",
      decision: "gate decision",
      action_guide: "gate action",
      data_info: "gate data"
    )

    sign_in(google_sub: "insight-free-user", status: "free")
    get "/insights"
    assert_response :redirect
    assert_redirected_to "/sessions"

    sign_in(google_sub: "insight-premium-user", status: "premium")
    get "/insights/#{insight.id}"
    assert_response :ok
  end
end
