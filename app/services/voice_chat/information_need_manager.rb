module VoiceChat
  class InformationNeedManager
    KEYWORD_MAP = {
      "external" => [ "외부", "데이터", "뉴스" ],
      "past" => [ "과거", "기록", "이전" ],
      "others" => [ "다른 사람", "의견", "조언" ],
      "inner" => [ "내 마음", "감정", "내면" ],
      "forgotten" => [ "잊", "놓친", "기억 안" ]
    }.freeze

    def classify(text:)
      KEYWORD_MAP.each_with_object({}) do |(type, keywords), result|
        result[type] = keywords.any? { |keyword| text.to_s.include?(keyword) }
      end
    end
  end
end
