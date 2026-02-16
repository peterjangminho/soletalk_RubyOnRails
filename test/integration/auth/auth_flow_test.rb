require "test_helper"
require "cgi"
require "uri"

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

  test "P68-T1 omniauth callback redirects to mobile handoff when allowlisted return uri is provided" do
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "google-sub-auth-3",
      info: {
        email: "auth3@example.com",
        name: "Auth Three"
      }
    )

    get "/auth/google_oauth2/callback", params: { mobile_return: "soletalk://auth" }

    assert_response :redirect
    location = response.headers["Location"]
    assert_match(/\Asoletalk:\/\/auth\?handoff=/, location)

    token = CGI.parse(URI.parse(location).query).fetch("handoff").first
    payload = ::Auth::MobileSessionHandoffToken.verify(token: token)
    user = User.find_by!(google_sub: "google-sub-auth-3")

    assert_not_nil payload
    assert_equal user.id.to_s, payload[:user_id]
    assert_equal user.google_sub, payload[:google_sub]
  end

  test "P68-T2 omniauth callback ignores non-allowlisted mobile return uri" do
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "google-sub-auth-4",
      info: {
        email: "auth4@example.com",
        name: "Auth Four"
      }
    )

    get "/auth/google_oauth2/callback", params: { mobile_return: "https://evil.example/path" }

    assert_response :redirect
    assert_redirected_to "/"
  end

  test "P68-T7 oauth start stores mobile return for callback handoff" do
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "google-sub-auth-7",
      info: {
        email: "auth7@example.com",
        name: "Auth Seven"
      }
    )

    get "/auth/google_oauth2/start", params: { mobile_return: "soletalk://auth" }
    assert_response :redirect
    assert_redirected_to "/auth/google_oauth2"

    get "/auth/google_oauth2/callback"
    assert_response :redirect
    assert_match(/\Asoletalk:\/\/auth\?handoff=/, response.headers["Location"])
  end

  test "P85-T1 oauth start redirects to consent when policy is not agreed for web flow" do
    get "/auth/google_oauth2/start"

    assert_response :redirect
    assert_redirected_to "/consent"
  end

  test "P85-T2 oauth start allows redirect to provider after consent is agreed" do
    post "/consent/accept", params: { agree: "1" }
    follow_redirect!

    get "/auth/google_oauth2/start"
    assert_response :redirect
    assert_redirected_to "/auth/google_oauth2"
  end

  test "P85-T3 guest sign in creates guest user session" do
    post "/guest_sign_in"
    assert_response :redirect
    assert_redirected_to "/"

    follow_redirect!
    get "/api/protected"
    assert_response :ok
  end
end
