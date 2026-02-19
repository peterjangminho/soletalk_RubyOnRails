require "test_helper"

class I18nFlowTest < ActionDispatch::IntegrationTest
  def sign_in(google_sub:)
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: google_sub,
      info: {
        email: "#{google_sub}@example.com",
        name: "I18n User"
      }
    )

    get "/auth/google_oauth2/callback"
    follow_redirect!

    User.find_by!(google_sub: google_sub)
  end

  test "P65-T1 guest home renders Korean copy when locale param is ko" do
    get "/?locale=ko"

    assert_response :ok
    assert_includes response.body, "로그인"
    assert_includes response.body, "Google로 계속하기"
  end

  test "P65-T2 session show uses Korean locale from user setting preference" do
    user = sign_in(google_sub: "i18n-session-user")
    user.settings.create!(language: "ko")
    session_record = user.sessions.create!(status: "active")
    VoiceChatData.create!(session: session_record, current_phase: "opener", emotion_level: 0.4)

    get "/sessions/#{session_record.id}"

    assert_response :ok
    assert_includes response.body, "음성 채팅 세션 ##{session_record.id}"
    assert_includes response.body, "디버그 도구 (Android 브리지)"
    assert_includes response.body, "data-default-label=\"전송\""
  end

  test "P65-T3 message flash follows Korean locale preference" do
    user = sign_in(google_sub: "i18n-message-user")
    user.settings.create!(language: "ko")
    session_record = user.sessions.create!(status: "active")

    post "/sessions/#{session_record.id}/messages", params: {
      message: { content: "안녕하세요" }
    }
    follow_redirect!

    assert_response :ok
    assert_includes response.body, "메시지가 전송되었습니다."
  end
end
