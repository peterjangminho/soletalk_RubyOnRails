require "test_helper"

class VoiceChatChannelTest < ActionCable::Channel::TestCase
  tests VoiceChatChannel

  test "P20-T1 subscribes only when session_id is present" do
    user = User.create!(google_sub: "channel-subscribe-user")
    session_record = Session.create!(user: user, status: "active")
    subscribe(session_id: session_record.id)

    assert subscription.confirmed?
    assert_has_stream "voice_chat:#{session_record.id}"

    unsubscribe

    subscribe
    assert subscription.rejected?
  end

  test "P20-T2 streams and broadcasts on per-session stream" do
    user = User.create!(google_sub: "channel-receive-user")
    session_record = Session.create!(user: user, status: "active")
    subscribe(session_id: session_record.id)

    assert_broadcast_on("voice_chat:#{session_record.id}", {
      "message" => "hello",
      "phase" => "opener",
      "emotion_level" => 0.7,
      "timestamp" => "2026-02-14T12:00:00Z"
    }) do
      perform :receive, {
        "message" => "hello",
        "phase" => "opener",
        "emotion_level" => 0.7,
        "timestamp" => "2026-02-14T12:00:00Z",
        "ignored" => "value"
      }
    end
  end

  test "P21-T2 replay returns missed messages and current phase snapshot" do
    user = User.create!(google_sub: "channel-replay-user")
    session_record = Session.create!(user: user, status: "active")
    VoiceChatData.create!(session: session_record, current_phase: "calm")
    older = Message.create!(session: session_record, role: "assistant", content: "old message")
    newer = Message.create!(session: session_record, role: "assistant", content: "new message")

    subscribe(session_id: session_record.id)

    assert_broadcast_on("voice_chat:#{session_record.id}", {
      "type" => "replay",
      "session_id" => session_record.id,
      "current_phase" => "calm",
      "messages" => [
        {
          "id" => newer.id,
          "role" => "assistant",
          "content" => "new message",
          "created_at" => newer.created_at.iso8601
        }
      ]
    }) do
      perform :replay, { "last_message_id" => older.id }
    end
  end

  test "P21-T3 rejects subscription for unknown session" do
    subscribe(session_id: -1)

    assert subscription.rejected?
  end
end
