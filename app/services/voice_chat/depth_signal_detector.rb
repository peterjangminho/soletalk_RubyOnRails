module VoiceChat
  class DepthSignalDetector
    def detect(emotion_level:, repetition_count:, text:)
      reasons = []
      reasons << :high_emotion if emotion_level >= Constants::DEPTH_TRIGGER[:emotion_level]
      reasons << :repetition if repetition_count >= Constants::DEPTH_TRIGGER[:repetition_count]

      if Constants::DEPTH_TRIGGER[:uncertainty_keywords].any? { |keyword| text.to_s.include?(keyword) }
        reasons << :uncertainty_keyword
      end

      {
        triggered: reasons.any?,
        reasons: reasons
      }
    end
  end
end
