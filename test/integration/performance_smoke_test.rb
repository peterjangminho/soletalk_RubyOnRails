require "test_helper"
require "benchmark"

class PerformanceSmokeTest < ActionDispatch::IntegrationTest
  test "P44-T3 performance smoke captures p95 baseline for /api/voice_chat/surface" do
    user = User.create!(google_sub: "g-perf-user")
    session_record = Session.create!(user: user, status: "active")
    VoiceChatData.create!(session: session_record, current_phase: "opener")

    latencies = []
    30.times do
      elapsed = Benchmark.realtime do
        post "/api/voice_chat/surface", params: {
          session_id: session_record.id,
          emotion_level: 0.7,
          turn_count: 2
        }, as: :json
      end
      assert_response :ok
      latencies << elapsed
    end

    sorted = latencies.sort
    p95 = sorted[(sorted.length * 0.95).ceil - 1]

    assert_operator p95, :<, 0.2
  end
end
