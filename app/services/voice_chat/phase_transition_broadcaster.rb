module VoiceChat
  class PhaseTransitionBroadcaster
    TARGET_ID = "voice_chat_phase_badge".freeze
    PARTIAL_PATH = "voice_chat/phase_badge".freeze

    def initialize(turbo_streams_channel: Turbo::StreamsChannel)
      @turbo_streams_channel = turbo_streams_channel
    end

    def call(session:, to_phase:, emotion_level:)
      @turbo_streams_channel.broadcast_replace_to(
        session,
        target: TARGET_ID,
        partial: PARTIAL_PATH,
        locals: {
          phase: to_phase,
          emotion_level: emotion_level
        }
      )
    end
  end
end
