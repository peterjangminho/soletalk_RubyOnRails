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

  test "P88-T1 GET /consent keeps agreement controls disabled before policy review action" do
    get "/consent"

    assert_response :ok
    assert_includes response.body, "data-controller=\"consent-gate\""
    assert_includes response.body, "id=\"consent_policy_review\""
    assert_includes response.body, "name=\"agree\""
    assert_includes response.body, "disabled=\"disabled\""
    assert_includes response.body, "value=\"Agree and continue\""
  end

  test "P88-T2 sign-up and consent cards expose auth visual parity hooks" do
    get "/sign_up"
    assert_response :ok
    assert_includes response.body, "auth-divider"
    assert_includes response.body, "auth-card auth-card-signup"

    get "/consent"
    assert_response :ok
    assert_includes response.body, "auth-card auth-card-consent"
    assert_includes response.body, "consent-note"
  end
end
