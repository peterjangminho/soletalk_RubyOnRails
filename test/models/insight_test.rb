require "test_helper"

class InsightTest < ActiveSupport::TestCase
  test "P3-T2 requires situation decision action_guide data_info" do
    insight = Insight.new

    assert_not insight.valid?
    assert_includes insight.errors[:situation], "can't be blank"
    assert_includes insight.errors[:decision], "can't be blank"
    assert_includes insight.errors[:action_guide], "can't be blank"
    assert_includes insight.errors[:data_info], "can't be blank"
  end

  test "P3-T3 persists engc_profile default safely" do
    insight = Insight.create!(
      situation: "Need to choose route",
      decision: "Take highway",
      action_guide: "Leave 10 minutes early",
      data_info: "Traffic data"
    )

    assert_equal({}, insight.engc_profile)
  end
end
