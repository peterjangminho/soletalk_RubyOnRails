require "test_helper"

class OnboardingControllerTest < ActionDispatch::IntegrationTest
  def sign_in(google_sub:)
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2", uid: google_sub,
      info: { email: "#{google_sub}@example.com", name: "Test User" }
    )
    get "/auth/google_oauth2/callback"
    follow_redirect!
  end

  test "GET /sign_up returns 200" do
    get "/sign_up"

    assert_response :ok
  end

  test "POST /sign_up redirects to consent" do
    post "/sign_up", params: { name: "Alice", email: "alice@example.com" }

    assert_redirected_to "/consent"
  end

  test "GET /consent returns 200" do
    get "/consent"

    assert_response :ok
  end

  test "POST /consent/accept without agree redirects with alert" do
    post "/consent/accept"

    assert_redirected_to "/consent"
    follow_redirect!
    assert_response :ok
    assert_includes response.body, "Please agree to continue."
  end

  test "POST /consent/accept with agree=1 sets policy_agreed and redirects" do
    post "/consent/accept", params: { agree: "1" }

    assert_redirected_to "/"
    follow_redirect!
    assert_response :ok
  end
end
