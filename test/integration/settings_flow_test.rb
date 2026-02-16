require "test_helper"

class SettingsFlowTest < ActionDispatch::IntegrationTest
  def sign_in(google_sub:)
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: google_sub,
      info: {
        email: "#{google_sub}@example.com",
        name: "Settings User"
      }
    )

    get "/auth/google_oauth2/callback"
    follow_redirect!
  end

  test "P26-T1 GET /setting renders current user setting form" do
    sign_in(google_sub: "setting-form-user")

    get "/setting"

    assert_response :ok
    assert_includes response.body, "Settings"
    assert_includes response.body, "voice_speed"
  end

  test "P28-T1 setting form includes Stimulus controller hook" do
    sign_in(google_sub: "setting-stimulus-user")

    get "/setting"

    assert_response :ok
    assert_includes response.body, "data-controller=\"settings-form\""
  end

  test "P26-T2 PATCH /setting updates language/voice_speed/preferences" do
    sign_in(google_sub: "setting-update-user")

    patch "/setting", params: {
      setting: {
        language: "en",
        voice_speed: 1.2,
        preferences_json: "{\"theme\":\"focus\"}"
      }
    }

    assert_redirected_to "/setting"
    setting = User.find_by!(google_sub: "setting-update-user").settings.order(:id).last
    assert_equal "en", setting.language
    assert_in_delta 1.2, setting.voice_speed, 0.001
    assert_equal({ "theme" => "focus" }, setting.preferences)
  end

  test "P26-T3 sessions and setting screens cross-link navigation" do
    sign_in(google_sub: "setting-nav-user")

    get "/sessions"
    assert_response :ok
    assert_includes response.body, "/setting"

    get "/setting"
    assert_response :ok
    assert_includes response.body, "/sessions"
  end

  test "P28-T3 importmap and stimulus bootstrap are wired in layout" do
    sign_in(google_sub: "setting-importmap-user")

    get "/setting"

    assert_response :ok
    assert_includes response.body, "type=\"importmap\""
    assert_includes response.body, "module"
  end

  test "P63-T2 PATCH /setting keeps preferences unchanged when preferences_json is invalid" do
    sign_in(google_sub: "setting-invalid-json-user")
    user = User.find_by!(google_sub: "setting-invalid-json-user")
    existing_setting = user.settings.create!(
      language: "en",
      voice_speed: 1.1,
      preferences: { "theme" => "focus" }
    )

    patch "/setting", params: {
      setting: {
        language: "ko",
        voice_speed: 1.0,
        preferences_json: "{\"theme\":\"broken\""
      }
    }

    assert_redirected_to "/setting"
    assert_equal({ "theme" => "focus" }, existing_setting.reload.preferences)
    follow_redirect!
    assert_includes response.body, "Invalid preferences JSON."
  end

  test "P78-T1 PATCH /setting uploads a reference file and keeps it on user" do
    sign_in(google_sub: "setting-file-upload-user")
    user = User.find_by!(google_sub: "setting-file-upload-user")
    upload = fixture_file_upload("sample_upload.txt", "text/plain")

    patch "/setting", params: {
      setting: {
        language: "en",
        voice_speed: 1.0,
        preferences_json: "{\"focus\":\"commute\"}",
        uploaded_file: upload
      }
    }

    assert_redirected_to "/setting"
    user.reload
    assert_equal 1, user.uploaded_files.attachments.count
    assert_equal "sample_upload.txt", user.uploaded_files.attachments.first.filename.to_s
  end

  test "P79-T2 GET /setting includes subscription restore form section" do
    sign_in(google_sub: "setting-subscription-user")

    get "/setting"

    assert_response :ok
    assert_includes response.body, "id=\"subscription\""
    assert_includes response.body, "/subscription/validate"
    assert_includes response.body, "Restore Subscription"
  end

  test "P82-T1 GET /setting renders particle hero stage for unified UI language" do
    sign_in(google_sub: "setting-particle-hero-user")

    get "/setting"

    assert_response :ok
    assert_includes response.body, "settings-hero-stage"
    assert_includes response.body, "data-controller=\"particle-orb\""
    assert_includes response.body, "data-particle-orb-mode-value=\"hero\""
  end
end
