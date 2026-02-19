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

  test "P24-T1 GET /sessions/new redirects to root (voice-only IA)" do
    sign_in(google_sub: "session-new-user")

    get "/sessions/new"

    assert_redirected_to "/"
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

  test "P24-T3 GET /sessions redirects to root (voice-only IA)" do
    sign_in(google_sub: "session-entry-user")

    get "/sessions"

    assert_redirected_to "/"
  end

  test "P63-T1 POST /sessions rolls back session when voice_chat_data initialization fails" do
    sign_in(google_sub: "session-create-failure-user")

    original_create = VoiceChatData.method(:create!)
    VoiceChatData.singleton_class.define_method(:create!) do |*|
      raise ActiveRecord::RecordInvalid.new(VoiceChatData.new)
    end

    begin
      assert_no_difference("Session.count") do
        assert_no_difference("VoiceChatData.count") do
          post "/sessions"
        end
      end
    ensure
      VoiceChatData.singleton_class.define_method(:create!, original_create)
    end

    assert_redirected_to "/"
    follow_redirect!
    assert_includes response.body, "Failed to start session."
  end

  test "P87-T1 POST /sessions with main mic entrypoint redirects with auto-start query" do
    sign_in(google_sub: "session-main-mic-entry-user")

    post "/sessions", params: { entrypoint: "main_mic" }

    created = Session.order(:id).last
    assert_redirected_to "/sessions/#{created.id}?auto_start_recording=1"
  end
end
