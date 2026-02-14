require "test_helper"

module Subscription
  class FeatureGateTest < ActiveSupport::TestCase
    test "P33-T1 computes daily session quota by tier" do
      free_user = User.create!(google_sub: "g-gate-free", subscription_status: "free")
      premium_user = User.create!(
        google_sub: "g-gate-premium",
        subscription_status: "premium",
        subscription_expires_at: 3.days.from_now
      )
      Session.create!(user: free_user, status: "active")

      gate = Subscription::FeatureGate.new

      assert_equal 1, gate.daily_session_remaining(free_user)
      assert_equal Float::INFINITY, gate.daily_session_remaining(premium_user)
    end

    test "P33-T2 enforces 7-day history for free tier" do
      free_user = User.create!(google_sub: "g-history-free", subscription_status: "free")
      premium_user = User.create!(
        google_sub: "g-history-premium",
        subscription_status: "premium",
        subscription_expires_at: 3.days.from_now
      )

      old_session = Session.create!(user: free_user, status: "completed", created_at: 10.days.ago)
      recent_session = Session.create!(user: free_user, status: "completed", created_at: 2.days.ago)

      gate = Subscription::FeatureGate.new

      assert_equal false, gate.history_accessible?(free_user, old_session)
      assert_equal true, gate.history_accessible?(free_user, recent_session)
      assert_equal true, gate.history_accessible?(premium_user, old_session)
    end
  end
end
