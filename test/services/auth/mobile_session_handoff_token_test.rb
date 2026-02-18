require "test_helper"

module Auth
  class MobileSessionHandoffTokenTest < ActiveSupport::TestCase
    test "P68-T5 generates and verifies token payload" do
      token = Auth::MobileSessionHandoffToken.generate(
        user_id: "101",
        google_sub: "g-mobile-1",
        expires_in: 10.minutes
      )
      payload = Auth::MobileSessionHandoffToken.verify(token: token)

      assert_not_nil payload
      assert_equal "101", payload[:user_id]
      assert_equal "g-mobile-1", payload[:google_sub]
    end

    test "P68-T6 returns nil for tampered token" do
      token = Auth::MobileSessionHandoffToken.generate(
        user_id: "102",
        google_sub: "g-mobile-2",
        expires_in: 10.minutes
      )
      payload = Auth::MobileSessionHandoffToken.verify(token: "#{token}x")

      assert_nil payload
    end
  end
end
