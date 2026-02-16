require "test_helper"

class OnboardingFlowTest < ActionDispatch::IntegrationTest
  test "P83-T1 GET /sign_up renders sign-up entry and continue path" do
    get "/sign_up"

    assert_response :ok
    assert_includes response.body, "Create account"
    assert_includes response.body, "/consent"
  end

  test "P83-T2 POST /sign_up redirects to consent screen" do
    post "/sign_up", params: {
      name: "New User",
      email: "new.user@example.com",
      password: "password123"
    }

    assert_redirected_to "/consent"
  end

  test "P83-T3 GET /consent exposes privacy and terms links" do
    get "/consent"

    assert_response :ok
    assert_includes response.body, "/legal/en/privacy-policy.html"
    assert_includes response.body, "/legal/en/terms-of-service.html"
    assert_includes response.body, "/consent/accept"
  end
end
