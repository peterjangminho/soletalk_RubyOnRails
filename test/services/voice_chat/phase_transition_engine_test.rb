require "test_helper"

class VoiceChatPhaseTransitionEngineTest < ActiveSupport::TestCase
  test "P12-T3 moves opener to emotion_expansion based on emotion" do
    engine = VoiceChat::PhaseTransitionEngine.new

    next_phase = engine.next_phase(
      current_phase: "opener",
      emotion_level: 0.6,
      turn_count: 2
    )

    assert_equal "emotion_expansion", next_phase
  end
end
