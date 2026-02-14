module VoiceChat
  module Constants
    PHASES = %w[opener emotion_expansion free_speech calm re_stimulus].freeze

    DEPTH_TRIGGER = {
      emotion_level: 0.8,
      repetition_count: 3,
      uncertainty_keywords: [ "모르겠", "어떻게", "불안" ]
    }.freeze
  end
end
