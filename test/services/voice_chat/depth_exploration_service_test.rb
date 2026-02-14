require "test_helper"

class VoiceChatDepthExplorationServiceTest < ActiveSupport::TestCase
  test "P15-T1 records q1~q4 answers to depth exploration" do
    service = VoiceChat::DepthExplorationService.new

    exploration = service.record(
      signal_emotion_level: 0.7,
      signal_keywords: [ "불안" ],
      q1_answer: "왜 중요한가",
      q2_answer: "무엇을 결정할지",
      q3_answer: "팀에 영향",
      q4_answer: "필요 정보",
      impacts: { emotional: "high" },
      information_needs: { external: [ "market" ] }
    )

    assert exploration.persisted?
    assert_equal "왜 중요한가", exploration.q1_answer
    assert_equal "필요 정보", exploration.q4_answer
    assert_equal "high", exploration.impacts["emotional"]
  end
end
