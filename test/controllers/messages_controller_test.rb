require "test_helper"

class MessagesControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  def sign_in(google_sub:)
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2", uid: google_sub,
      info: { email: "#{google_sub}@example.com", name: "Test User" }
    )
    get "/auth/google_oauth2/callback"
    follow_redirect!
  end

  test "POST /sessions/:id/messages creates message and redirects" do
    sign_in(google_sub: "g-messages-create")
    user = User.find_by!(google_sub: "g-messages-create")
    session_record = Session.create!(user: user, status: "active")

    assert_difference "Message.count", 1 do
      post "/sessions/#{session_record.id}/messages", params: { message: { content: "Hello world" } }
    end

    message = Message.last
    assert_equal "user", message.role
    assert_equal "Hello world", message.content
    assert_equal session_record.id, message.session_id

    assert_response :redirect
    assert_redirected_to session_path(session_record)
  end

  test "POST /sessions/:id/messages unauthenticated redirects" do
    user = User.create!(google_sub: "g-messages-noauth-owner")
    session_record = Session.create!(user: user, status: "active")

    post "/sessions/#{session_record.id}/messages", params: { message: { content: "Hello" } }

    assert_response :redirect
    assert_redirected_to "/"
  end

  test "POST /sessions/:id/messages for other user's session returns not_found" do
    other_user = User.create!(google_sub: "g-messages-other-owner")
    other_session = Session.create!(user: other_user, status: "active")

    sign_in(google_sub: "g-messages-not-owner")

    post "/sessions/#{other_session.id}/messages", params: { message: { content: "Hello" } }

    assert_response :not_found
  end
end
