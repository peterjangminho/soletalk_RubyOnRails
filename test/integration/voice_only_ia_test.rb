require "test_helper"

class VoiceOnlyIaTest < ActionDispatch::IntegrationTest
  def sign_in(google_sub:)
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: google_sub,
      info: {
        email: "#{google_sub}@example.com",
        name: "Voice IA User"
      }
    )

    get "/auth/google_oauth2/callback"
    follow_redirect!
  end

  # --- Phase 1: Route/Exposure Reduction ---

  test "VO-P1-T1 signed-in GET /sessions redirects to root" do
    sign_in(google_sub: "vo-sessions-redirect")

    get "/sessions"

    assert_redirected_to "/"
  end

  test "VO-P1-T2 signed-in GET /sessions/new redirects to root" do
    sign_in(google_sub: "vo-new-session-redirect")

    get "/sessions/new"

    assert_redirected_to "/"
  end

  test "VO-P1-T3 signed-in GET /insights redirects to root" do
    sign_in(google_sub: "vo-insights-redirect")

    get "/insights"

    assert_redirected_to "/"
  end

  test "VO-P1-T4 signed-in home page has no top-nav-shell anywhere" do
    sign_in(google_sub: "vo-no-topnav")

    get "/"

    assert_response :ok
    assert_not_includes response.body, "top-nav-shell"
  end

  test "VO-P1-T5 settings page has no top-nav-shell" do
    sign_in(google_sub: "vo-settings-no-topnav")

    get "/setting"

    assert_response :ok
    assert_not_includes response.body, "top-nav-shell"
  end

  test "VO-P1-T6 settings back button links to root not sessions" do
    sign_in(google_sub: "vo-settings-back-root")

    get "/setting"

    assert_response :ok
    assert_includes response.body, "href=\"/\""
    assert_not_includes response.body, "settings-back-btn\" href=\"/sessions\""
  end

  # --- Phase 2: Home Voice Stage ---

  test "VO-P2-T1 signed-in home has no text message input or textarea" do
    sign_in(google_sub: "vo-no-text-form")

    get "/"

    assert_response :ok
    assert_not_includes response.body, "message[content]"
    assert_not_includes response.body, "<textarea"
    assert_not_includes response.body, "type=\"text\""
  end

  test "VO-P2-T3 signed-in home wraps orb and mic in voice-stage controller" do
    sign_in(google_sub: "vo-voice-stage")

    get "/"

    assert_response :ok
    assert_match(/data-controller="[^"]*voice-stage/, response.body)
    assert_includes response.body, "data-voice-stage-target=\"sphere\""
  end

  test "VO-P2-T4 signed-in home has bridge-unavailable fallback target" do
    sign_in(google_sub: "vo-bridge-fallback")

    get "/"

    assert_response :ok
    assert_includes response.body, "data-voice-stage-target=\"bridgeFallback\""
  end

  test "VO-P2-T2 signed-in home shows only particle sphere, mic, upload icon, settings icon" do
    sign_in(google_sub: "vo-voice-elements")

    get "/"

    assert_response :ok
    assert_includes response.body, "particle-sphere"
    assert_includes response.body, "mic-button"
    assert_includes response.body, "icon-upload-cloud"
    assert_includes response.body, "icon-cog"
    # No sessions/insights navigation links
    assert_not_includes response.body, "href=\"/sessions\""
    assert_not_includes response.body, "href=\"/insights\""
  end

  # --- Phase 3: Quick Upload + Bottom Sheet ---

  test "VO-P3-T1 upload icon triggers quick-upload controller not settings navigation" do
    sign_in(google_sub: "vo-quick-upload-icon")

    get "/"

    assert_response :ok
    # Upload icon should trigger quick-upload, not navigate to settings#uploads
    assert_not_includes response.body, "href=\"/setting#uploads\""
    assert_match(/data-controller="[^"]*quick-upload/, response.body)
    assert_includes response.body, "data-action=\"click->quick-upload#openFilePicker\""
  end

  test "VO-P3-T2 home has bottom sheet markup for upload confirmation" do
    sign_in(google_sub: "vo-bottom-sheet")

    get "/"

    assert_response :ok
    assert_includes response.body, "upload-bottom-sheet"
    assert_includes response.body, "data-quick-upload-target=\"sheet\""
    assert_includes response.body, "data-quick-upload-target=\"fileInfo\""
    assert_includes response.body, "data-action=\"click->quick-upload#confirm\""
    assert_includes response.body, "data-action=\"click->quick-upload#cancel\""
  end

  test "VO-P3-T3 POST /voice/context_files uploads file and returns success" do
    sign_in(google_sub: "vo-upload-api")
    user = User.find_by!(google_sub: "vo-upload-api")
    file = fixture_file_upload("sample_upload.txt", "text/plain")

    assert_difference -> { user.uploaded_files.count }, 1 do
      post "/voice/context_files", params: { file: file }
    end

    assert_response :success
    parsed = JSON.parse(response.body)
    assert_equal "ok", parsed["status"]
    assert parsed["filename"].present?
  end

  test "VO-P3-T4 POST /voice/context_files without file returns error" do
    sign_in(google_sub: "vo-upload-no-file")

    post "/voice/context_files", params: {}

    assert_response :unprocessable_entity
    parsed = JSON.parse(response.body)
    assert_equal "error", parsed["status"]
  end

  # --- Phase 5: Policy Modal + Settings Info ---

  test "VO-P5-T1 home page includes policy modal partial" do
    sign_in(google_sub: "vo-policy-modal")

    get "/"

    assert_response :ok
    assert_includes response.body, "policy-modal"
    assert_match(/data-controller="[^"]*policy-modal/, response.body)
  end

  test "VO-P5-T2 policy modal has close button and escape support" do
    sign_in(google_sub: "vo-policy-close")

    get "/"

    assert_response :ok
    assert_includes response.body, "data-action=\"click->policy-modal#close\""
    assert_includes response.body, "data-action=\"keydown.esc@window->policy-modal#close\""
  end

  test "VO-P5-T3 settings page has policy info section with links" do
    sign_in(google_sub: "vo-settings-policy")

    get "/setting"

    assert_response :ok
    assert_includes response.body, "id=\"policy\""
    assert_includes response.body, t("settings.show.policy.title")
    assert_includes response.body, t("settings.show.policy.privacy_link")
    assert_includes response.body, t("settings.show.policy.terms_link")
  end

  test "VO-P5-T4 policy modal contains privacy and terms content" do
    sign_in(google_sub: "vo-policy-content")

    get "/"

    assert_response :ok
    assert_includes response.body, t("policy_modal.privacy_title")
    assert_includes response.body, t("policy_modal.terms_title")
  end

  # --- Phase 6: Settings Screen Project_B Style Alignment ---

  test "VO-P6-T1 settings has language and data as separate identified sections" do
    sign_in(google_sub: "vo-p6-sections")

    get "/setting"

    assert_response :ok
    assert_includes response.body, 'id="language"'
    assert_includes response.body, 'id="data"'
  end

  test "VO-P6-T2 settings sections ordered: language data subscription policy account" do
    sign_in(google_sub: "vo-p6-order")

    get "/setting"

    assert_response :ok
    body = response.body
    ids = %w[language data subscription policy account]
    positions = ids.map { |id| body.index("id=\"#{id}\"") }
    ids.each_with_index { |id, i| assert positions[i], "section id=#{id} must exist" }
    assert_equal positions, positions.sort, "sections must appear in order: #{ids.join(' → ')}"
  end

  test "VO-P6-T3 subscription section preserved after settings restructure" do
    sign_in(google_sub: "vo-p6-subscription")

    get "/setting"

    assert_response :ok
    assert_includes response.body, 'id="subscription"'
    assert_includes response.body, t("subscription.show.title")
  end

  private

  def t(key, **opts)
    I18n.t(key, **opts)
  end
end
