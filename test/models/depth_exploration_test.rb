require "test_helper"

class DepthExplorationTest < ActiveSupport::TestCase
  test "P3-T1 validates signal_emotion_level range" do
    exploration = DepthExploration.new(
      signal_emotion_level: 1.2,
      signal_keywords: [ "anxiety" ],
      q1_answer: "Q1",
      q2_answer: "Q2",
      q3_answer: "Q3",
      q4_answer: "Q4"
    )

    assert_not exploration.valid?
    assert_includes exploration.errors[:signal_emotion_level], "must be less than or equal to 1"
  end

  test "P3-T1 requires q1~q4 answers" do
    exploration = DepthExploration.new(signal_emotion_level: 0.5)

    assert_not exploration.valid?
    assert_includes exploration.errors[:q1_answer], "can't be blank"
    assert_includes exploration.errors[:q2_answer], "can't be blank"
    assert_includes exploration.errors[:q3_answer], "can't be blank"
    assert_includes exploration.errors[:q4_answer], "can't be blank"
  end

  test "P3-T3 persists json fields with defaults" do
    exploration = DepthExploration.create!(
      signal_emotion_level: 0.4,
      signal_keywords: [ "stress" ],
      q1_answer: "Because of deadline",
      q2_answer: "Delay release",
      q3_answer: "Communicate with team",
      q4_answer: "Need schedule data"
    )

    assert_equal [ "stress" ], exploration.signal_keywords
    assert_equal({}, exploration.impacts)
    assert_equal({}, exploration.information_needs)
  end
end
