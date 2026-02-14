require "test_helper"

class InsightNaturalSpeechTest < ActiveSupport::TestCase
  test "P17-T1 formats situation/decision/action/data into sentence" do
    text = Insight::NaturalSpeech.format(
      situation: "회의 일정이 촉박하고",
      decision: "범위를 줄일지 고민이며",
      action_guide: "핵심 기능부터 배포하고",
      data_info: "사용자 로그를 먼저 확인하는 것"
    )

    assert_includes text, "회의 일정이 촉박하고"
    assert_includes text, "범위를 줄일지 고민이며"
    assert_includes text, "핵심 기능부터 배포하고"
    assert_includes text, "사용자 로그를 먼저 확인하는 것"
  end
end
