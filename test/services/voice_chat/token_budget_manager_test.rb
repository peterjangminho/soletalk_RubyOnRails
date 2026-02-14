require "test_helper"

class VoiceChatTokenBudgetManagerTest < ActiveSupport::TestCase
  test "P16-T2 allocates token budget by ratio" do
    manager = VoiceChat::TokenBudgetManager.new(total_tokens: 1000)

    budget = manager.allocate

    assert_equal 100, budget[:profile]
    assert_equal 200, budget[:past_memory]
    assert_equal 300, budget[:current_session]
    assert_equal 150, budget[:additional_info]
    assert_equal 150, budget[:ai_persona]
  end
end
