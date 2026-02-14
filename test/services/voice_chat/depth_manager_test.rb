require "test_helper"

class VoiceChatDepthManagerTest < ActiveSupport::TestCase
  test "P14-T2 tracks depth progress and completion" do
    manager = VoiceChat::DepthManager.new

    manager.record_answer(:q1, "a1")
    manager.record_answer(:q2, "a2")

    assert_equal 0.5, manager.progress
    assert_not manager.completed?

    manager.record_answer(:q3, "a3")
    manager.record_answer(:q4, "a4")

    assert_equal 1.0, manager.progress
    assert manager.completed?
  end
end
