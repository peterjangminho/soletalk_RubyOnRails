require "test_helper"

class AuthFlowTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  test "P9-T1 authenticate_user! redirects when session is missing" do
    get "/api/protected"

    assert_response :redirect
    assert_redirected_to "/"
  end

  test "P9-T2 omniauth callback creates user and signs in session" do
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "google-sub-auth-1",
      info: {
        email: "auth1@example.com",
        name: "Auth One"
      }
    )

    get "/auth/google_oauth2/callback"

    assert_response :redirect
    assert User.exists?(google_sub: "google-sub-auth-1")

    follow_redirect!
    get "/api/protected"
    assert_response :ok
  end

  test "P9-T3 omniauth failure redirects safely" do
    get "/auth/failure"

    assert_response :redirect
    assert_redirected_to "/"
  end

  test "P10-T3 omniauth callback enqueues identify user job" do
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "google-sub-auth-2",
      info: {
        email: "auth2@example.com",
        name: "Auth Two"
      }
    )

    assert_enqueued_with(job: OntologyRag::IdentifyUserJob, args: [ "google-sub-auth-2" ]) do
      get "/auth/google_oauth2/callback"
    end
  end
end
