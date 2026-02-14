require "test_helper"

class UserSubscriptionTest < ActiveSupport::TestCase
  test "P32-T1 user subscription fields support premium predicate" do
    user = User.create!(
      google_sub: "g-sub-premium",
      subscription_status: "premium",
      subscription_expires_at: 2.days.from_now
    )

    assert_equal true, user.premium?

    user.update!(subscription_expires_at: 1.day.ago)
    assert_equal false, user.premium?
  end
end
