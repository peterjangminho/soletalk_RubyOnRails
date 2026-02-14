require "test_helper"

class SessionMessagesFlowTest < ActionDispatch::IntegrationTest
  def sign_in(google_sub:)
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: google_sub,
      info: {
        email: "#{google_sub}@example.com",
        name: "Message User"
      }
    )

    get "/auth/google_oauth2/callback"
    follow_redirect!
  end

  test "P23-T1 session show renders message stream in chronological order" do
    sign_in(google_sub: "message-stream-user")
    user = User.find_by!(google_sub: "message-stream-user")
    session_record = Session.create!(user: user, status: "active")
    Message.create!(session: session_record, role: "assistant", content: "first message")
    Message.create!(session: session_record, role: "assistant", content: "second message")

    get "/sessions/#{session_record.id}"

    assert_response :ok
    assert_operator response.body.index("first message"), :<, response.body.index("second message")
  end

  test "P28-T2 session message form includes Stimulus controller hook" do
    sign_in(google_sub: "message-stimulus-user")
    user = User.find_by!(google_sub: "message-stimulus-user")
    session_record = Session.create!(user: user, status: "active")

    get "/sessions/#{session_record.id}"

    assert_response :ok
    assert_includes response.body, "data-controller=\"message-form\""
  end

  test "P23-T2 POST /sessions/:session_id/messages creates user message" do
    sign_in(google_sub: "message-create-user")
    user = User.find_by!(google_sub: "message-create-user")
    session_record = Session.create!(user: user, status: "active")

    assert_difference("Message.count", 1) do
      post "/sessions/#{session_record.id}/messages", params: { message: { content: "hello world" } }
    end

    assert_redirected_to "/sessions/#{session_record.id}"
    created = Message.order(:id).last
    assert_equal "user", created.role
    assert_equal "hello world", created.content
  end

  test "P23-T3 POST /sessions/:session_id/messages rejects access to other user's session" do
    sign_in(google_sub: "message-owner-user")
    owner = User.find_by!(google_sub: "message-owner-user")
    other_session = Session.create!(user: owner, status: "active")

    sign_in(google_sub: "message-outsider-user")

    assert_no_difference("Message.count") do
      post "/sessions/#{other_session.id}/messages", params: { message: { content: "unauthorized" } }
    end

    assert_response :not_found
  end
end
