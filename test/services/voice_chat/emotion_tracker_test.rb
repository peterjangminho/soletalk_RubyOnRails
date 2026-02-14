require "test_helper"

class VoiceChatEmotionTrackerTest < ActiveSupport::TestCase
  test "P13-T1 updates and clamps emotion/energy levels" do
    tracker = VoiceChat::EmotionTracker.new

    result = tracker.update(emotion_delta: 0.7, energy_delta: 0.8)
    assert_in_delta 0.7, result[:emotion_level], 0.001
    assert_in_delta 0.8, result[:energy_level], 0.001

    result = tracker.update(emotion_delta: 1.0, energy_delta: 1.0)
    assert_in_delta 1.0, result[:emotion_level], 0.001
    assert_in_delta 1.0, result[:energy_level], 0.001

    result = tracker.update(emotion_delta: -2.0, energy_delta: -2.0)
    assert_in_delta 0.0, result[:emotion_level], 0.001
    assert_in_delta 0.0, result[:energy_level], 0.001
  end
end
