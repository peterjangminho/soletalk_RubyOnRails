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
    assert_includes response.body, "href=\"/auth/google_oauth2/start\""
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
    assert_includes response.body, "action=\"/sessions\""
  end

  test "UX-T1 signed-in root page does not expose raw google_sub identifier text" do
    sign_in(google_sub: "home-private-user")

    get "/"

    assert_response :ok
    assert_not_includes response.body, "Signed in with Google Sub"
  end

  test "P72-T1 root page renders cinematic app shell" do
    get "/"

    assert_response :ok
    assert_includes response.body, "class=\"app-shell\""
  end

  test "UI-T1 guest pages hide top nav bar" do
    get "/"
    assert_response :ok
    assert_not_includes response.body, "top-nav-shell"

    get "/consent"
    assert_response :ok
    assert_not_includes response.body, "top-nav-shell"
  end

  test "UI-T2 signed-in pages show top nav bar" do
    sign_in(google_sub: "nav-test-user")

    get "/"
    assert_response :ok
    assert_includes response.body, "top-nav-shell"
  end

  test "P72-T2 guest root page renders login screen with opening animation" do
    get "/"

    assert_response :ok
    assert_includes response.body, "login-screen"
    assert_includes response.body, "login-card"
    assert_includes response.body, "data-controller=\"opening-animation\""
  end

  test "P79-T3 signed-in navigation removes standalone subscription tab and uses settings" do
    sign_in(google_sub: "home-settings-nav-user")

    get "/"

    assert_response :ok
    assert_includes response.body, "href=\"/setting\""
    assert_not_includes response.body, "href=\"/subscription\""
  end

  test "P80-T1 signed-in home uses Project_B brand assets (logo in nav)" do
    sign_in(google_sub: "brand-logo-user")

    get "/"

    assert_response :ok
    assert_includes response.body, "/brand/soletalk-logo-v2.png"
  end

  test "P85-T3 guest home shows actionable guest entry after policy consent" do
    post "/consent/accept", params: { agree: "1" }
    follow_redirect!

    get "/"

    assert_response :ok
    assert_includes response.body, "/guest_sign_in"
  end

  test "P87-T2 signed-in home main mic form includes main_mic entrypoint hidden field" do
    sign_in(google_sub: "home-main-mic-entrypoint-user")

    get "/"

    assert_response :ok
    assert_includes response.body, "name=\"entrypoint\""
    assert_includes response.body, "value=\"main_mic\""
  end
end
