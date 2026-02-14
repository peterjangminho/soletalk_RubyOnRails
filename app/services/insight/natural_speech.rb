class Insight::NaturalSpeech
  def self.format(situation:, decision:, action_guide:, data_info:)
    "지금은 #{situation}, #{decision}, #{action_guide}, #{data_info}가 좋겠습니다."
  end
end
