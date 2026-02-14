require "test_helper"

class VoiceChatDepthSignalDetectorTest < ActiveSupport::TestCase
  test "P12-T2 detects depth signal on high emotion" do
    detector = VoiceChat::DepthSignalDetector.new

    result = detector.detect(
      emotion_level: 0.9,
      repetition_count: 0,
      text: "괜찮아요"
    )

    assert_equal true, result[:triggered]
    assert_includes result[:reasons], :high_emotion
  end

  test "P12-T2 detects depth signal on uncertainty keywords" do
    detector = VoiceChat::DepthSignalDetector.new

    result = detector.detect(
      emotion_level: 0.3,
      repetition_count: 0,
      text: "잘 모르겠어요"
    )

    assert_equal true, result[:triggered]
    assert_includes result[:reasons], :uncertainty_keyword
  end
end
