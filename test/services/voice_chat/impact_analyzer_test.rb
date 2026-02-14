require "test_helper"

class VoiceChatImpactAnalyzerTest < ActiveSupport::TestCase
  test "P15-T2 returns 5-dimension impact summary" do
    analyzer = VoiceChat::ImpactAnalyzer.new

    result = analyzer.analyze(
      text: "감정적으로 힘들고 팀 관계도 걱정되고, 커리어랑 재정도 불안해요"
    )

    assert_equal %w[emotional relational career financial psychological].sort, result.keys.sort
    assert_equal true, result["emotional"]
  end
end
