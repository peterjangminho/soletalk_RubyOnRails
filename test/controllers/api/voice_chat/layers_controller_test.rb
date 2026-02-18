require "test_helper"

module Api
  module VoiceChat
    class LayersControllerTest < ActionDispatch::IntegrationTest
      test "P38-T1 POST /api/voice_chat/surface returns next phase payload" do
        user = User.create!(google_sub: "g-layer-surface")
        session_record = Session.create!(user: user, status: "active")
        VoiceChatData.create!(session: session_record, current_phase: "opener")

        post "/api/voice_chat/surface", params: {
          session_id: session_record.id,
          emotion_level: 0.8,
          turn_count: 1
        }, as: :json

        assert_response :ok
        body = JSON.parse(response.body)
        assert_equal true, body["success"]
        assert_equal "emotion_expansion", body["next_phase"]
      end

      test "P38-T2 POST /api/voice_chat/depth persists depth exploration answers" do
        assert_difference("DepthExploration.count", 1) do
          post "/api/voice_chat/depth", params: {
            signal_emotion_level: 0.7,
            signal_keywords: [ "stress" ],
            q1_answer: "why",
            q2_answer: "decision",
            q3_answer: "impact",
            q4_answer: "data",
            impacts: { emotional: "high" },
            information_needs: { external: true }
          }, as: :json
        end

        assert_response :ok
        body = JSON.parse(response.body)
        assert_equal true, body["success"]
        assert body["depth_exploration_id"].present?
      end

      test "P38-T3 POST /api/voice_chat/insight creates insight from depth answers" do
        user = User.create!(google_sub: "g-layer-insight")
        session_record = Session.create!(user: user, status: "active")

        assert_difference("Insight.count", 1) do
          post "/api/voice_chat/insight", params: {
            session_id: session_record.id,
            q1_answer: "situation",
            q2_answer: "decision",
            q3_answer: "action",
            q4_answer: "data"
          }, as: :json
        end

        assert_response :ok
        body = JSON.parse(response.body)
        assert_equal true, body["success"]
        assert body["insight_id"].present?
      end
    end
  end
end
