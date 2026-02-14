module Subscription
  class EntitlementChecker
    def can_use_external_info?(user)
      user.premium?
    end

    def can_access_depth?(user)
      user.premium?
    end

    def can_access_insight?(user)
      user.premium?
    end
  end
end
