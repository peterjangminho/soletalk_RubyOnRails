module VoiceChat
  class EmotionTracker
    def initialize(emotion_level: 0.0, energy_level: 0.0)
      @emotion_level = emotion_level
      @energy_level = energy_level
    end

    def update(emotion_delta:, energy_delta:)
      @emotion_level = clamp(@emotion_level + emotion_delta)
      @energy_level = clamp(@energy_level + energy_delta)

      {
        emotion_level: @emotion_level,
        energy_level: @energy_level
      }
    end

    private

    def clamp(value)
      return 0.0 if value < 0.0
      return 1.0 if value > 1.0

      value
    end
  end
end
