module VoiceChat
  class DepthExplorationService
    def record(
      signal_emotion_level:,
      signal_keywords:,
      q1_answer:,
      q2_answer:,
      q3_answer:,
      q4_answer:,
      impacts: {},
      information_needs: {},
      signal_repetition_count: 0
    )
      DepthExploration.create!(
        signal_emotion_level: signal_emotion_level,
        signal_keywords: signal_keywords,
        signal_repetition_count: signal_repetition_count,
        q1_answer: q1_answer,
        q2_answer: q2_answer,
        q3_answer: q3_answer,
        q4_answer: q4_answer,
        impacts: impacts,
        information_needs: information_needs
      )
    end
  end
end
