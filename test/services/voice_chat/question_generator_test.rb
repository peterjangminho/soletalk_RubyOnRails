require "test_helper"

class VoiceChatQuestionGeneratorTest < ActiveSupport::TestCase
  test "P14-T1 provides Q1~Q4 prompts" do
    generator = VoiceChat::QuestionGenerator.new

    assert_includes generator.question_for(:q1), "왜"
    assert_includes generator.question_for(:q2), "결정"
    assert_includes generator.question_for(:q3), "영향"
    assert_includes generator.question_for(:q4), "정보"
  end
end
