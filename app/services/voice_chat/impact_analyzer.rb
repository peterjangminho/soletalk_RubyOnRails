module VoiceChat
  class ImpactAnalyzer
    KEYWORD_MAP = {
      "emotional" => [ "감정", "불안", "힘들" ],
      "relational" => [ "관계", "팀", "가족" ],
      "career" => [ "커리어", "직장", "일" ],
      "financial" => [ "재정", "돈", "비용" ],
      "psychological" => [ "심리", "스트레스", "압박" ]
    }.freeze

    def analyze(text:)
      KEYWORD_MAP.each_with_object({}) do |(dimension, keywords), result|
        result[dimension] = keywords.any? { |keyword| text.to_s.include?(keyword) }
      end
    end
  end
end
