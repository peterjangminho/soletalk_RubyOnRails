require "test_helper"

module Subscription
  class SyncServiceTest < ActiveSupport::TestCase
    class FakeClient
      cattr_accessor :response

      def fetch_subscriber(revenue_cat_id:)
        self.class.response
      end
    end

    test "P34-T3 sync service updates user status from RevenueCat payload" do
      user = User.create!(
        google_sub: "g-sync-user",
        revenue_cat_id: "rc_sync",
        subscription_status: "free"
      )
      FakeClient.response = {
        premium: true,
        expires_at: 3.days.from_now
      }

      service = Subscription::SyncService.new(client: FakeClient.new)
      result = service.call(user: user)

      assert_equal true, result[:success]
      user.reload
      assert_equal "premium", user.subscription_status
      assert_equal "premium", user.subscription_tier
      assert user.subscription_expires_at.present?
    end
  end
end
