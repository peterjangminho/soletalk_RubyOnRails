require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  def sign_in(google_sub:)
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2", uid: google_sub,
      info: { email: "#{google_sub}@example.com", name: "Test User" }
    )
    get "/auth/google_oauth2/callback"
    follow_redirect!
  end

  test "guest GET / returns 200" do
    get "/"

    assert_response :ok
  end

  test "signed-in GET / returns 200 and loads sessions and insights" do
    sign_in(google_sub: "g-home-signed-in")
    user = User.find_by!(google_sub: "g-home-signed-in")
    session_record = Session.create!(user: user, status: "active")
    Insight.create!(
      user: user,
      situation: "situation",
      decision: "decision",
      action_guide: "action",
      data_info: "data"
    )

    get "/"

    assert_response :ok
    assert_select "main.main-screen"
  end

  test "guest does not see main-screen content" do
    get "/"

    assert_response :ok
    assert_select "main.main-screen", count: 0
    assert_select "main.login-screen"
  end
end
