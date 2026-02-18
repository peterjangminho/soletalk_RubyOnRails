require "test_helper"

class InsightsFlowTest < ActionDispatch::IntegrationTest
  def sign_in(google_sub:)
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: google_sub,
      info: {
        email: "#{google_sub}@example.com",
        name: "Insight User"
      }
    )

    get "/auth/google_oauth2/callback"
    follow_redirect!
    user = User.find_by!(google_sub: google_sub)
    user.update!(
      subscription_status: "premium",
      subscription_tier: "premium",
      subscription_expires_at: 2.days.from_now
    )
    user
  end

  test "P18-T1 GET /insights redirects to root (voice-only IA)" do
    sign_in(google_sub: "insight-index-user")

    get "/insights"

    assert_redirected_to "/"
  end

  test "P25-T1 GET /insights redirects to root (voice-only IA)" do
    sign_in(google_sub: "insight-timeline-user")

    get "/insights"

    assert_redirected_to "/"
  end

  test "P18-T2 GET /insights/:id redirects to root (voice-only IA)" do
    user = sign_in(google_sub: "insight-show-user")
    insight = Insight.create!(
      user: user,
      situation: "selected situation",
      decision: "selected decision",
      action_guide: "selected action",
      data_info: "selected data"
    )

    get "/insights/#{insight.id}"

    assert_redirected_to "/"
  end

  test "P25-T2 GET /insights/:id redirects to root (voice-only IA)" do
    user = sign_in(google_sub: "insight-q-user")
    insight = Insight.create!(
      user: user,
      situation: "q1 detail",
      decision: "q2 detail",
      action_guide: "q3 detail",
      data_info: "q4 detail"
    )

    get "/insights/#{insight.id}"

    assert_redirected_to "/"
  end

  test "P64-T1 GET /insights/:id redirects to root regardless of ownership (voice-only IA)" do
    owner = sign_in(google_sub: "insight-owner-user")
    insight = Insight.create!(
      user: owner,
      situation: "private situation",
      decision: "private decision",
      action_guide: "private action",
      data_info: "private data"
    )

    sign_in(google_sub: "insight-other-user")
    get "/insights/#{insight.id}"

    assert_redirected_to "/"
  end
end
