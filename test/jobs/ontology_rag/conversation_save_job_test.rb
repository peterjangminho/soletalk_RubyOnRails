require "test_helper"

class OntologyRagConversationSaveJobTest < ActiveJob::TestCase
  class FakeClient
    cattr_accessor :received_payload

    def save_conversation(session_id:, google_sub:, conversation:, metadata:)
      self.class.received_payload = {
        session_id: session_id,
        google_sub: google_sub,
        conversation: conversation,
        metadata: metadata
      }
      { "success" => true }
    end
  end

  test "P29-T2 ConversationSaveJob sends session transcript to OntologyRag::Client#save_conversation" do
    original = OntologyRag::ConversationSaveJob.client_class
    OntologyRag::ConversationSaveJob.client_class = FakeClient

    user = User.create!(google_sub: "g-conv-job")
    session_record = Session.create!(user: user, status: "completed")
    Message.create!(session: session_record, role: "user", content: "hello")
    Message.create!(session: session_record, role: "assistant", content: "hi")

    OntologyRag::ConversationSaveJob.perform_now(session_record.id)

    payload = FakeClient.received_payload
    assert_equal session_record.id.to_s, payload[:session_id]
    assert_equal "g-conv-job", payload[:google_sub]
    assert_equal 2, payload[:conversation].size
    assert_equal "hello", payload[:conversation][0][:content]
    assert_equal "hi", payload[:conversation][1][:content]
    assert_equal "session_end", payload[:metadata][:source]
  ensure
    OntologyRag::ConversationSaveJob.client_class = original if original
  end

  test "P29-T3 ConversationSaveJob applies retry policy of 3 attempts" do
    assert_equal 3, OntologyRag::ConversationSaveJob::RETRY_ATTEMPTS
  end
end
