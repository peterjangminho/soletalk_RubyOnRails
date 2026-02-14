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

  test "P25-T3 session show renders DEPTH panel and recent insights panel" do
    sign_in(google_sub: "sessions-depth-user")
    user = User.find_by!(google_sub: "sessions-depth-user")
    session_record = Session.create!(user: user, status: "active")
    VoiceChatData.create!(session: session_record, current_phase: "free_speech", emotion_level: 0.7)
    Insight.create!(
      situation: "insight panel situation",
      decision: "insight panel decision",
      action_guide: "insight panel action",
      data_info: "insight panel data"
    )

    get "/sessions/#{session_record.id}"

    assert_response :ok
    assert_includes response.body, "depth-panel"
    assert_includes response.body, "recent-insights-panel"
    assert_includes response.body, "insight panel situation"
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
end
