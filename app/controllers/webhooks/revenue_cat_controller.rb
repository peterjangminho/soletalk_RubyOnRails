module Webhooks
  class RevenueCatController < ApplicationController
    skip_forgery_protection

    def create
      user = User.find_by!(google_sub: params.require(:google_sub))
      event_type = params.require(:event_type)

      apply_subscription_event(user, event_type)

      render json: { success: true }
    end

    private

    def apply_subscription_event(user, event_type)
      case event_type
      when "INITIAL_PURCHASE", "RENEWAL"
        user.update!(
          subscription_status: "premium",
          subscription_tier: "premium",
          subscription_expires_at: parse_time(params[:expires_at]),
          revenue_cat_id: params[:revenue_cat_id].presence || user.revenue_cat_id
        )
      when "EXPIRATION"
        user.update!(
          subscription_status: "free",
          subscription_tier: "free",
          subscription_expires_at: nil
        )
      end
    end

    def parse_time(value)
      return nil if value.blank?

      Time.zone.parse(value)
    end
  end
end
