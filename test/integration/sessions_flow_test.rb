require "test_helper"

class SessionsFlowTest < ActionDispatch::IntegrationTest
  def sign_in(google_sub:)
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: google_sub,
      info: {
        email: "#{google_sub}@example.com",
        name: "Session User"
      }
    )

    get "/auth/google_oauth2/callback"
    follow_redirect!
  end

  test "P22-T1 GET /sessions renders current user's sessions list" do
    sign_in(google_sub: "sessions-index-user")
    me = User.find_by!(google_sub: "sessions-index-user")
    mine = Session.create!(user: me, status: "active")

    other_user = User.create!(google_sub: "sessions-other-user")
    other = Session.create!(user: other_user, status: "active")

    get "/sessions"

    assert_response :ok
    assert_includes response.body, "/sessions/#{mine.id}"
    assert_not_includes response.body, "/sessions/#{other.id}"
  end

  test "P22-T2 GET /sessions/:id renders voice chat page with turbo_stream_from session" do
    sign_in(google_sub: "sessions-show-user")
    user = User.find_by!(google_sub: "sessions-show-user")
    session_record = Session.create!(user: user, status: "active")
    VoiceChatData.create!(session: session_record, current_phase: "emotion_expansion", emotion_level: 0.6)

    get "/sessions/#{session_record.id}"

    assert_response :ok
    assert_includes response.body, "turbo-cable-stream-source"
    assert_includes response.body, "data-session-id=\"#{session_record.id}\""
    assert_includes response.body, "data-native-bridge=\"voice\""
    assert_includes response.body, "SoleTalkBridge.setSession(\"#{session_record.id}\", \"sessions-show-user\", \""
  end

  test "P22-T3 session show includes phase badge target for turbo replacement" do
    sign_in(google_sub: "sessions-phase-user")
    user = User.find_by!(google_sub: "sessions-phase-user")
    session_record = Session.create!(user: user, status: "active")
    VoiceChatData.create!(session: session_record, current_phase: "calm", emotion_level: 0.2)

    get "/sessions/#{session_record.id}"

    assert_response :ok
    assert_includes response.body, "id=\"voice_chat_phase_badge\""
    assert_includes response.body, "data-phase=\"calm\""
  end

  test "P60-T1 session show renders native bridge control panel" do
    sign_in(google_sub: "sessions-native-bridge-user")
    user = User.find_by!(google_sub: "sessions-native-bridge-user")
    session_record = Session.create!(user: user, status: "active")

    get "/sessions/#{session_record.id}"

    assert_response :ok
    assert_includes response.body, "native-bridge-panel"
    assert_includes response.body, "data-controller=\"native-bridge\""
    assert_includes response.body, "native-bridge#startRecording"
    assert_includes response.body, "native-bridge#stopRecording"
  end

  test "P60-T2 session show exposes transcription/location/tts bridge actions" do
    sign_in(google_sub: "sessions-native-bridge-controls-user")
    user = User.find_by!(google_sub: "sessions-native-bridge-controls-user")
    session_record = Session.create!(user: user, status: "active")

    get "/sessions/#{session_record.id}"

    assert_response :ok
    assert_includes response.body, "native-bridge#sendTranscription"
    assert_includes response.body, "native-bridge#sendLocation"
    assert_includes response.body, "native-bridge#requestCurrentLocation"
    assert_includes response.body, "native-bridge#playAudio"
  end

  test "UX-T2 session show wraps native bridge controls in debug details with live status" do
    sign_in(google_sub: "sessions-native-bridge-debug-user")
    user = User.find_by!(google_sub: "sessions-native-bridge-debug-user")
    session_record = Session.create!(user: user, status: "active")

    get "/sessions/#{session_record.id}"

    assert_response :ok
    assert_includes response.body, "native-bridge-debug"
    assert_includes response.body, "Debug Tools (Android Bridge)"
    assert_includes response.body, "aria-live=\"polite\""
  end

  test "P63-T3 session show exposes default submit label metadata for message form controller" do
    sign_in(google_sub: "sessions-submit-label-user")
    user = User.find_by!(google_sub: "sessions-submit-label-user")
    session_record = Session.create!(user: user, status: "active")

    get "/sessions/#{session_record.id}"

    assert_response :ok
    assert_includes response.body, "data-message-form-target=\"submit\""
    assert_includes response.body, "data-default-label=\"Send\""
  end

  test "P25-T3 session show renders DEPTH panel and recent insights panel" do
    sign_in(google_sub: "sessions-depth-user")
    user = User.find_by!(google_sub: "sessions-depth-user")
    session_record = Session.create!(user: user, status: "active")
    VoiceChatData.create!(session: session_record, current_phase: "free_speech", emotion_level: 0.7)
    Insight.create!(
      user: user,
      situation: "insight panel situation",
      decision: "insight panel decision",
      action_guide: "insight panel action",
      data_info: "insight panel data"
    )
    Insight.create!(
      user: User.create!(google_sub: "sessions-depth-other-user"),
      situation: "other user insight",
      decision: "other user decision",
      action_guide: "other user action",
      data_info: "other user data"
    )

    get "/sessions/#{session_record.id}"

    assert_response :ok
    assert_includes response.body, "depth-panel"
    assert_includes response.body, "recent-insights-panel"
    assert_includes response.body, "insight panel situation"
    assert_not_includes response.body, "other user insight"
  end

  test "P27-T1 session show renders emotion gauge with current emotion value" do
    sign_in(google_sub: "sessions-emotion-user")
    user = User.find_by!(google_sub: "sessions-emotion-user")
    session_record = Session.create!(user: user, status: "active")
    VoiceChatData.create!(session: session_record, current_phase: "free_speech", emotion_level: 0.8)

    get "/sessions/#{session_record.id}"

    assert_response :ok
    assert_includes response.body, "emotion-gauge"
    assert_includes response.body, "value=\"0.8\""
  end

  test "P27-T2 emotion gauge renders fallback 0.0 when voice_chat_data absent" do
    sign_in(google_sub: "sessions-emotion-fallback-user")
    user = User.find_by!(google_sub: "sessions-emotion-fallback-user")
    session_record = Session.create!(user: user, status: "active")

    get "/sessions/#{session_record.id}"

    assert_response :ok
    assert_includes response.body, "emotion-gauge"
    assert_includes response.body, "value=\"0.0\""
  end

  test "P69-T3 session show exposes particle orb motion phase and emotion metadata" do
    sign_in(google_sub: "sessions-orb-phase-user")
    user = User.find_by!(google_sub: "sessions-orb-phase-user")
    session_record = Session.create!(user: user, status: "active")
    VoiceChatData.create!(session: session_record, current_phase: "free_speech", emotion_level: 0.8)

    get "/sessions/#{session_record.id}"

    assert_response :ok
    assert_includes response.body, "data-controller=\"particle-orb\""
    assert_includes response.body, "data-particle-orb-phase-value=\"free_speech\""
    assert_includes response.body, "data-particle-orb-emotion-value=\"0.8\""
  end

  test "P72-T3 session show renders cinematic conversation stack container" do
    sign_in(google_sub: "sessions-conversation-shell-user")
    user = User.find_by!(google_sub: "sessions-conversation-shell-user")
    session_record = Session.create!(user: user, status: "active")

    get "/sessions/#{session_record.id}"

    assert_response :ok
    assert_includes response.body, "id=\"messages\""
    assert_includes response.body, "conversation-stack"
  end

  test "P80-T3 session show uses Project_B-style overlay layout shells" do
    sign_in(google_sub: "sessions-overlay-layout-user")
    user = User.find_by!(google_sub: "sessions-overlay-layout-user")
    session_record = Session.create!(user: user, status: "active")

    get "/sessions/#{session_record.id}"

    assert_response :ok
    assert_includes response.body, "session-stage"
    assert_includes response.body, "session-overlay-top"
    assert_includes response.body, "session-overlay-bottom"
  end
end
