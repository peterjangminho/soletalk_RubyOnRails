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

  test "P88-T1 GET /consent checkbox is enabled and submit is disabled by default" do
    get "/consent"

    assert_response :ok
    assert_includes response.body, "data-controller=\"consent-gate\""
    assert_includes response.body, "name=\"agree\""
    assert_includes response.body, "value=\"Agree and continue\""

    # Checkbox should be enabled (not disabled) so users can click it
    doc = response.body
    checkbox_match = doc[/(<input[^>]*name="agree"[^>]*>)/]
    assert checkbox_match, "Expected agree checkbox in the form"
    assert_not_includes checkbox_match, "disabled", "Checkbox should not be disabled"

    # Submit button should be disabled until checkbox is checked
    submit_match = doc[/(<input[^>]*value="Agree and continue"[^>]*>)/]
    assert submit_match, "Expected submit button in the form"
    assert_includes submit_match, "disabled", "Submit button should be disabled by default"
  end

  test "P88-T2 sign-up and consent cards expose auth visual parity hooks" do
    get "/sign_up"
    assert_response :ok
    assert_includes response.body, "auth-divider"
    assert_includes response.body, "auth-card auth-card-signup"

    get "/consent"
    assert_response :ok
    assert_includes response.body, "auth-card auth-card-consent"
    assert_includes response.body, "consent-checkbox"
  end
end
