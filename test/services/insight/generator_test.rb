require "test_helper"

class InsightGeneratorTest < ActiveSupport::TestCase
  test "P17-T2 creates insight record from depth answers" do
    generator = Insight::Generator.new

    insight = generator.call(
      q1_answer: "회의 일정이 촉박",
      q2_answer: "범위를 줄일지 고민",
      q3_answer: "팀 피로를 줄여야 함",
      q4_answer: "최근 릴리즈 지표 필요"
    )

    assert insight.persisted?
    assert_equal "회의 일정이 촉박", insight.situation
    assert_equal "범위를 줄일지 고민", insight.decision
    assert_equal "팀 피로를 줄여야 함", insight.action_guide
    assert_equal "최근 릴리즈 지표 필요", insight.data_info
  end
end
