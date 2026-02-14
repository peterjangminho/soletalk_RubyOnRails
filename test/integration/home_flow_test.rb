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
  end

  test "P54-T2 signed-in root page shows navigation and recent lists" do
    sign_in(google_sub: "home-signed-user")
    user = User.find_by!(google_sub: "home-signed-user")
    session_record = Session.create!(user: user, status: "active")
    Insight.create!(
      situation: "home insight situation",
      decision: "home insight decision",
      action_guide: "home insight action",
      data_info: "home insight data"
    )

    get "/"

    assert_response :ok
    assert_includes response.body, "Welcome"
    assert_includes response.body, "/sessions/new"
    assert_includes response.body, "/sessions/#{session_record.id}"
    assert_includes response.body, "home insight situation"
  end
end
