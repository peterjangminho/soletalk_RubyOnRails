require "test_helper"

class VoiceChatConstantsTest < ActiveSupport::TestCase
  test "P12-T1 defines 5 phase sequence and trigger thresholds" do
    phases = VoiceChat::Constants::PHASES
    assert_equal %w[opener emotion_expansion free_speech calm re_stimulus], phases

    thresholds = VoiceChat::Constants::DEPTH_TRIGGER
    assert_operator thresholds[:emotion_level], :>, 0
    assert_operator thresholds[:repetition_count], :>=, 1
    assert_includes thresholds[:uncertainty_keywords], "모르겠"
  end
end
