require "test_helper"

class VoiceChatPhaseTransitionBroadcasterTest < ActiveSupport::TestCase
  test "P21-T1 publishes turbo stream phase badge update" do
    user = User.create!(google_sub: "phase-broadcast-user")
    session = Session.create!(user: user, status: "active")

    calls = []
    broadcaster = VoiceChat::PhaseTransitionBroadcaster.new(
      turbo_streams_channel: Class.new do
        class << self
          attr_accessor :calls
        end

        def self.broadcast_replace_to(*args, **kwargs)
          self.calls << { args: args, kwargs: kwargs }
        end
      end
    )
    broadcaster.instance_variable_get(:@turbo_streams_channel).calls = calls

    broadcaster.call(session: session, to_phase: "emotion_expansion", emotion_level: 0.8)

    assert_equal 1, calls.size
    assert_equal [ session ], calls.first[:args]
    assert_equal "voice_chat_phase_badge", calls.first[:kwargs][:target]
    assert_equal "voice_chat/phase_badge", calls.first[:kwargs][:partial]
    assert_equal "emotion_expansion", calls.first[:kwargs][:locals][:phase]
    assert_equal 0.8, calls.first[:kwargs][:locals][:emotion_level]
  end
end
