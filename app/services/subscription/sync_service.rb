module Subscription
  class SyncService
    def initialize(client: Subscription::RevenueCatClient.new)
      @client = client
    end

    def call(user:)
      return { success: false, error: "revenue_cat_id_missing" } if user.revenue_cat_id.blank?

      result = @client.fetch_subscriber(revenue_cat_id: user.revenue_cat_id)

      if result[:premium]
        user.update!(
          subscription_status: "premium",
          subscription_tier: "premium",
          subscription_expires_at: result[:expires_at]
        )
      else
        user.update!(
          subscription_status: "free",
          subscription_tier: "free",
          subscription_expires_at: nil
        )
      end

      { success: true, premium: user.premium? }
    end
  end
end
