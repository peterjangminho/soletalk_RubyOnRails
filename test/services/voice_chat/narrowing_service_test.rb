require "test_helper"

class VoiceChatNarrowingServiceTest < ActiveSupport::TestCase
  test "P13-T2 generates progressively focused questions" do
    service = VoiceChat::NarrowingService.new

    q1 = service.next_question(stage: 1, topic: "일")
    q2 = service.next_question(stage: 2, topic: "일")
    q3 = service.next_question(stage: 3, topic: "일")

    assert_includes q1, "일"
    assert_includes q2, "구체적"
    assert_includes q3, "지금 당장"
  end
end
