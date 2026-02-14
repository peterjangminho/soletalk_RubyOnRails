require "test_helper"

module Voice
  class BridgeMessageTest < ActiveSupport::TestCase
    test "P36-T1 validates allowed native bridge actions" do
      valid = Voice::BridgeMessage.new(action: "transcription", session_id: "1", payload: { text: "hello" })
      invalid = Voice::BridgeMessage.new(action: "unknown", session_id: "1", payload: {})

      assert_equal true, valid.valid?
      assert_equal false, invalid.valid?
    end
  end
end
