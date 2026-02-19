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
    assert_includes response.body, "href=\"/auth/google_oauth2/start?consent_accepted=1\""
  end

  test "P54-T2 signed-in root page shows main screen with particle sphere and mic" do
    sign_in(google_sub: "home-signed-user")

    get "/"

    assert_response :ok
    assert_includes response.body, "home-opening-overlay"
    assert_includes response.body, "data-controller=\"opening-animation\""
    assert_includes response.body, "main-orb-stage"
    assert_includes response.body, "home-main-mic"
    assert_not_includes response.body, "action=\"/sessions\""
    assert_includes response.body, "href=\"/voice/context_files\""
    assert_includes response.body, "mic-button:state-changed->native-bridge#micStateChanged"
    assert_includes response.body, "particle-sphere"
    # Main screen has no text content - only icons and mic
    assert_not_includes response.body, "Welcome"
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

  test "UI-T2 signed-in sessions page redirects to root (voice-only IA)" do
    sign_in(google_sub: "nav-test-user")

    # Home hides top nav
    get "/"
    assert_response :ok
    assert_not_includes response.body, "top-nav-shell"

    # Sessions page redirects to root in voice-only mode
    get "/sessions"
    assert_redirected_to "/"
  end

  test "P72-T2 guest root page renders login screen without opening animation" do
    get "/"

    assert_response :ok
    assert_includes response.body, "login-screen"
    assert_includes response.body, "login-card"
    assert_not_includes response.body, "data-controller=\"opening-animation\""
  end

  test "P79-T3 signed-in navigation removes standalone subscription tab and uses settings" do
    sign_in(google_sub: "home-settings-nav-user")

    get "/"

    assert_response :ok
    assert_includes response.body, "href=\"/setting\""
    assert_not_includes response.body, "href=\"/subscription\""
  end

  test "P80-T1 signed-in session show does not expose top text-box navigation chips" do
    sign_in(google_sub: "brand-logo-user")
    user = User.find_by!(google_sub: "brand-logo-user")
    session_record = Session.create!(user: user, status: "active")

    get "/sessions/#{session_record.id}"

    assert_response :ok
    assert_not_includes response.body, "top-nav-shell"
  end

  test "P85-T3 guest home shows actionable guest entry after policy consent" do
    post "/consent/accept", params: { agree: "1" }
    follow_redirect!

    get "/"

    assert_response :ok
    assert_includes response.body, "/guest_sign_in"
  end

  test "UI-T4 signed-in main top bar uses icon-only links (no text labels)" do
    sign_in(google_sub: "icon-topbar-user")

    get "/"

    assert_response :ok
    # Icon-only links: upload-cloud for file upload, cog for settings
    assert_includes response.body, "icon-upload-cloud"
    assert_includes response.body, "icon-cog"
    # No text labels in top bar
    assert_not_includes response.body, ">File Upload<"
  end

  test "UI-T5 signed-in main screen mic button has toggle data action" do
    sign_in(google_sub: "mic-toggle-user")

    get "/"

    assert_response :ok
    assert_includes response.body, "mic-button#toggle"
  end

  test "P87-T2 signed-in home binds native bridge session payload on main screen" do
    sign_in(google_sub: "home-main-mic-entrypoint-user")

    get "/"

    assert_response :ok
    assert_includes response.body, "data-native-bridge-session-id-value="
    assert_includes response.body, "data-native-bridge-google-sub-value=\"home-main-mic-entrypoint-user\""
    assert_includes response.body, "data-native-bridge-bridge-token-value="
  end
end
