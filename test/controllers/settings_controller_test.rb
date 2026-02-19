require "test_helper"

class SettingsControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  def sign_in(google_sub:)
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2", uid: google_sub,
      info: { email: "#{google_sub}@example.com", name: "Test User" }
    )
    get "/auth/google_oauth2/callback"
    follow_redirect!
  end

  test "GET /setting redirects unauthenticated users" do
    get "/setting"

    assert_response :redirect
    assert_redirected_to "/"
  end

  test "GET /setting shows settings for signed-in user" do
    sign_in(google_sub: "g-settings-show")

    get "/setting"

    assert_response :ok
  end

  test "PATCH /setting updates language" do
    sign_in(google_sub: "g-settings-lang")
    user = User.find_by!(google_sub: "g-settings-lang")

    patch "/setting", params: { setting: { language: "en" } }

    assert_redirected_to "/setting"
    setting = user.settings.order(:id).last
    assert_equal "en", setting.language
  end

  test "PATCH /setting with invalid JSON shows alert" do
    sign_in(google_sub: "g-settings-bad-json")
    user = User.find_by!(google_sub: "g-settings-bad-json")
    user.settings.create!(language: "ko", voice_speed: 1.0, preferences: { "theme" => "dark" })

    patch "/setting", params: { setting: { preferences_json: "{broken" } }

    assert_redirected_to "/setting"
    follow_redirect!
    assert_response :ok

    setting = user.settings.order(:id).last
    assert_equal({ "theme" => "dark" }, setting.preferences)
  end
end
