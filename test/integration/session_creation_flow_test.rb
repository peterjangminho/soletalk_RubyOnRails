require "test_helper"

class SessionCreationFlowTest < ActionDispatch::IntegrationTest
  def sign_in(google_sub:)
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: google_sub,
      info: {
        email: "#{google_sub}@example.com",
        name: "Create Session User"
      }
    )

    get "/auth/google_oauth2/callback"
    follow_redirect!
  end

  test "P24-T1 GET /sessions/new renders new session form" do
    sign_in(google_sub: "session-new-user")

    get "/sessions/new"

    assert_response :ok
    assert_includes response.body, "<form"
    assert_includes response.body, "Start Session"
  end

  test "P24-T2 POST /sessions creates active session and initializes voice_chat_data" do
    sign_in(google_sub: "session-create-user")

    assert_difference("Session.count", 1) do
      assert_difference("VoiceChatData.count", 1) do
        post "/sessions"
      end
    end

    created = Session.order(:id).last
    assert_equal "active", created.status
    assert_redirected_to "/sessions/#{created.id}"
    assert_equal "opener", created.voice_chat_data.current_phase
  end

  test "P24-T3 sessions index exposes new session entry point" do
    sign_in(google_sub: "session-entry-user")

    get "/sessions"

    assert_response :ok
    assert_includes response.body, "/sessions/new"
  end
end
