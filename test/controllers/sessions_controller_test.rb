require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  def sign_in(google_sub:)
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2", uid: google_sub,
      info: { email: "#{google_sub}@example.com", name: "Test User" }
    )
    get "/auth/google_oauth2/callback"
    follow_redirect!
  end

  test "GET /sessions redirects unauthenticated users" do
    get "/sessions"

    assert_response :redirect
    assert_redirected_to "/"
  end

  test "GET /sessions redirects to root for voice-only IA" do
    sign_in(google_sub: "g-sessions-index")

    get "/sessions"

    assert_response :redirect
    assert_redirected_to "/"
  end

  test "POST /sessions creates session with VoiceChatData" do
    sign_in(google_sub: "g-sessions-create")

    assert_difference [ "Session.count", "VoiceChatData.count" ], 1 do
      post "/sessions"
    end

    session_record = Session.last
    assert_equal "active", session_record.status
    assert_equal "opener", session_record.voice_chat_data.current_phase

    assert_response :redirect
    assert_redirected_to session_path(session_record)
  end

  test "POST /sessions with entrypoint=main_mic redirects with auto_start_recording" do
    sign_in(google_sub: "g-sessions-mic")

    post "/sessions", params: { entrypoint: "main_mic" }

    session_record = Session.last
    assert_response :redirect
    assert_redirected_to session_path(session_record, auto_start_recording: "1")
  end

  test "GET /sessions/:id shows session for owner" do
    sign_in(google_sub: "g-sessions-show")
    user = User.find_by!(google_sub: "g-sessions-show")
    session_record = Session.create!(user: user, status: "active")
    VoiceChatData.create!(session: session_record, current_phase: "opener")

    get "/sessions/#{session_record.id}"

    assert_response :ok
  end

  test "GET /sessions/:id returns not_found for other user's session" do
    other_user = User.create!(google_sub: "g-sessions-other-owner")
    other_session = Session.create!(user: other_user, status: "active")

    sign_in(google_sub: "g-sessions-not-owner")

    get "/sessions/#{other_session.id}"

    assert_response :not_found
  end
end
