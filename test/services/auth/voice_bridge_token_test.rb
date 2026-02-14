require "test_helper"

module Auth
  class VoiceBridgeTokenTest < ActiveSupport::TestCase
    test "P61-T1 generates and verifies token payload" do
      token = Auth::VoiceBridgeToken.generate(session_id: "10", google_sub: "g-voice-1", expires_in: 10.minutes)
      payload = Auth::VoiceBridgeToken.verify(token: token)

      assert_not_nil payload
      assert_equal "10", payload[:session_id]
      assert_equal "g-voice-1", payload[:google_sub]
    end

    test "P61-T2 returns nil for tampered token" do
      token = Auth::VoiceBridgeToken.generate(session_id: "11", google_sub: "g-voice-2", expires_in: 10.minutes)
      payload = Auth::VoiceBridgeToken.verify(token: "#{token}x")

      assert_nil payload
    end
  end
end
