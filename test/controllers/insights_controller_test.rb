require "test_helper"

class InsightsControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  def sign_in(google_sub:)
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2", uid: google_sub,
      info: { email: "#{google_sub}@example.com", name: "Test User" }
    )
    get "/auth/google_oauth2/callback"
    follow_redirect!
  end

  test "GET /insights redirects unauthenticated" do
    get "/insights"

    assert_response :redirect
    assert_redirected_to "/"
  end

  test "GET /insights redirects to root for voice-only IA" do
    sign_in(google_sub: "g-insights-index")

    get "/insights"

    assert_response :redirect
    assert_redirected_to "/"
  end

  test "GET /insights/:id redirects to root for voice-only IA" do
    sign_in(google_sub: "g-insights-show")
    user = User.find_by!(google_sub: "g-insights-show")
    insight = Insight.create!(
      user: user,
      situation: "situation",
      decision: "decision",
      action_guide: "action",
      data_info: "data"
    )

    get "/insights/#{insight.id}"

    assert_response :redirect
    assert_redirected_to "/"
  end
end
