require "test_helper"

class E2eVoicechatFlowTest < ActionDispatch::IntegrationTest
  class FakeSaveClient
    cattr_accessor :saved_payload

    def save_conversation(session_id:, google_sub:, conversation:, metadata:)
      self.class.saved_payload = {
        session_id: session_id,
        google_sub: google_sub,
        conversation: conversation,
        metadata: metadata
      }
      { "success" => true }
    end
  end

  def sign_in(google_sub:, premium: false)
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: google_sub,
      info: {
        email: "#{google_sub}@example.com",
        name: "E2E User"
      }
    )

    get "/auth/google_oauth2/callback"
    follow_redirect!
    user = User.find_by!(google_sub: google_sub)
    if premium
      user.update!(subscription_status: "premium", subscription_tier: "premium", subscription_expires_at: 2.days.from_now)
    else
      user.update!(subscription_status: "free", subscription_tier: "free", subscription_expires_at: nil)
    end
    user
  end

  test "P42-T1 E2E SURFACE->DEPTH->INSIGHT flow succeeds via API endpoints" do
    user = User.create!(google_sub: "e2e-flow-user")
    session_record = Session.create!(user: user, status: "active")
    VoiceChatData.create!(session: session_record, current_phase: "opener")

    post "/api/voice_chat/surface", params: {
      session_id: session_record.id,
      emotion_level: 0.9,
      turn_count: 1
    }, as: :json
    assert_response :ok
    assert_equal "emotion_expansion", JSON.parse(response.body)["next_phase"]

    post "/api/voice_chat/depth", params: {
      signal_emotion_level: 0.9,
      signal_keywords: [ "stress" ],
      q1_answer: "why",
      q2_answer: "decision",
      q3_answer: "impact",
      q4_answer: "data"
    }, as: :json
    assert_response :ok
    depth_id = JSON.parse(response.body)["depth_exploration_id"]
    assert DepthExploration.exists?(depth_id)

    post "/api/voice_chat/insight", params: {
      q1_answer: "why",
      q2_answer: "decision",
      q3_answer: "impact",
      q4_answer: "data"
    }, as: :json
    assert_response :ok
    insight_id = JSON.parse(response.body)["insight_id"]
    assert Insight.exists?(insight_id)
  end

  test "P42-T2 E2E Auth->Chat->Insight->Save flow persists conversation and insight" do
    user = sign_in(google_sub: "e2e-auth-user", premium: true)
    session_record = Session.create!(user: user, status: "active")
    original_client = OntologyRag::ConversationSaveJob.client_class
    OntologyRag::ConversationSaveJob.client_class = FakeSaveClient
    FakeSaveClient.saved_payload = nil

    post "/sessions/#{session_record.id}/messages", params: { message: { content: "hello from e2e" } }
    assert_redirected_to "/sessions/#{session_record.id}"

    post "/api/voice_chat/insight", params: {
      q1_answer: "situation",
      q2_answer: "decision",
      q3_answer: "action",
      q4_answer: "data"
    }, as: :json
    assert_response :ok
    assert Insight.exists?(JSON.parse(response.body)["insight_id"])

    OntologyRag::ConversationSaveJob.perform_now(session_record.id)
    assert_equal session_record.id.to_s, FakeSaveClient.saved_payload[:session_id]
    assert_equal "e2e-auth-user", FakeSaveClient.saved_payload[:google_sub]
    assert_equal "hello from e2e", FakeSaveClient.saved_payload[:conversation][0][:content]
  ensure
    OntologyRag::ConversationSaveJob.client_class = original_client if original_client
  end

  test "P42-T3 E2E free-tier gating blocks insight access while premium allows" do
    Insight.create!(situation: "s1", decision: "d1", action_guide: "a1", data_info: "i1")

    sign_in(google_sub: "e2e-free-user", premium: false)
    get "/insights"
    assert_response :redirect

    sign_in(google_sub: "e2e-prem-user", premium: true)
    get "/insights"
    assert_response :ok
  end

  test "P55-T3 E2E voice event flow start transcription stop location succeeds" do
    user = sign_in(google_sub: "e2e-voice-events-user", premium: true)
    session_record = Session.create!(user: user, status: "active")

    post "/api/voice/events", params: {
      event_action: "start_recording",
      session_id: session_record.id,
      payload: {}
    }, as: :json
    assert_response :ok

    post "/api/voice/events", params: {
      event_action: "transcription",
      session_id: session_record.id,
      payload: { text: "voice from native bridge" }
    }, as: :json
    assert_response :ok

    post "/api/voice/events", params: {
      event_action: "stop_recording",
      session_id: session_record.id,
      payload: {}
    }, as: :json
    assert_response :ok

    post "/api/voice/events", params: {
      event_action: "location_update",
      session_id: session_record.id,
      payload: { latitude: 37.0, longitude: 127.0, weather: "clear" }
    }, as: :json
    assert_response :ok

    session_record.reload
    assert_equal "voice from native bridge", session_record.messages.order(:created_at).last.content
    assert_equal false, session_record.voice_chat_data.metadata["recording_active"]
    assert_equal 37.0, session_record.voice_chat_data.metadata["last_location"]["latitude"]
  end
end
