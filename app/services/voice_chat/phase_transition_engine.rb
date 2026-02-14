module VoiceChat
  class PhaseTransitionEngine
    def next_phase(current_phase:, emotion_level:, turn_count:)
      return "emotion_expansion" if current_phase == "opener" && (emotion_level >= 0.5 || turn_count >= 2)

      current_phase
    end
  end
end
