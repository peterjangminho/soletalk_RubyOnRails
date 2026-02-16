require "test_helper"

class HomeFlowTest < ActionDispatch::IntegrationTest
  def sign_in(google_sub:)
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: google_sub,
      info: {
        email: "#{google_sub}@example.com",
        name: "Home User"
      }
    )

    get "/auth/google_oauth2/callback"
    follow_redirect!
  end

  test "P54-T1 guest root page shows google sign in entry point" do
    get "/"

    assert_response :ok
    assert_includes response.body, "SoleTalk"
    assert_includes response.body, "Continue with Google"
    assert_includes response.body, "/auth/google_oauth2"
    assert_includes response.body, "href=\"/auth/google_oauth2\""
  end

  test "P54-T2 signed-in root page shows navigation and recent lists" do
    sign_in(google_sub: "home-signed-user")
    user = User.find_by!(google_sub: "home-signed-user")
    session_record = Session.create!(user: user, status: "active")
    Insight.create!(
      user: user,
      situation: "home insight situation",
      decision: "home insight decision",
      action_guide: "home insight action",
      data_info: "home insight data"
    )
    Insight.create!(
      user: User.create!(google_sub: "home-signed-other-user"),
      situation: "other user home insight",
      decision: "other user decision",
      action_guide: "other user action",
      data_info: "other user data"
    )

    get "/"

    assert_response :ok
    assert_includes response.body, "Welcome"
    assert_includes response.body, "/sessions/new"
    assert_includes response.body, "/sessions/#{session_record.id}"
    assert_includes response.body, "home insight situation"
    assert_not_includes response.body, "other user home insight"
    assert_includes response.body, "href=\"/setting#uploads\""
    assert_includes response.body, "main-orb-stage"
    assert_includes response.body, "home-main-mic"
  end

  test "UX-T1 signed-in root page does not expose raw google_sub identifier text" do
    sign_in(google_sub: "home-private-user")

    get "/"

    assert_response :ok
    assert_not_includes response.body, "Signed in with Google Sub"
  end

  test "P72-T1 root page renders cinematic app shell and glass navigation" do
    get "/"

    assert_response :ok
    assert_includes response.body, "class=\"app-shell\""
    assert_includes response.body, "class=\"top-nav-shell glass-nav\""
  end

  test "P72-T2 guest root page renders dedicated home orb stage class" do
    get "/"

    assert_response :ok
    assert_includes response.body, "orb-hero orb-hero-home"
    assert_includes response.body, "home-hero-stage"
    assert_includes response.body, "data-particle-orb-mode-value=\"hero\""
  end

  test "P79-T3 signed-in navigation removes standalone subscription tab and uses settings" do
    sign_in(google_sub: "home-settings-nav-user")

    get "/"

    assert_response :ok
    assert_includes response.body, "href=\"/setting\""
    assert_not_includes response.body, "href=\"/subscription\""
  end

  test "P80-T1 guest home uses Project_B brand assets (logo and feature graphic)" do
    get "/"

    assert_response :ok
    assert_includes response.body, "/brand/soletalk-logo-v2.png"
    assert_includes response.body, "/brand/projectb-feature-graphic.png"
  end
end
