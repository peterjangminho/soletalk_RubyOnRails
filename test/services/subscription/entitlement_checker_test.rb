require "test_helper"

module Subscription
  class EntitlementCheckerTest < ActiveSupport::TestCase
    test "P32-T2 gates premium-only features" do
      free_user = User.create!(google_sub: "g-ent-free", subscription_status: "free")
      premium_user = User.create!(
        google_sub: "g-ent-premium",
        subscription_status: "premium",
        subscription_expires_at: 3.days.from_now
      )

      checker = Subscription::EntitlementChecker.new

      assert_equal false, checker.can_use_external_info?(free_user)
      assert_equal true, checker.can_use_external_info?(premium_user)
    end
  end
end
