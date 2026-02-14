require "test_helper"

class VoiceChatInformationNeedManagerTest < ActiveSupport::TestCase
  test "P15-T3 classifies info needs by type" do
    manager = VoiceChat::InformationNeedManager.new

    result = manager.classify(
      text: "외부 데이터와 과거 기록, 그리고 다른 사람 의견이 필요해요"
    )

    assert_equal %w[external past others inner forgotten].sort, result.keys.sort
    assert_equal true, result["external"]
    assert_equal true, result["past"]
    assert_equal true, result["others"]
  end
end
