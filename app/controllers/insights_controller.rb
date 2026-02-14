class InsightsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_premium_access!

  class_attribute :entitlement_checker_class, default: Subscription::EntitlementChecker

  def index
    @insights = Insight.order(created_at: :desc)
  end

  def show
    @insight = Insight.find(params[:id])
  end

  private

  def require_premium_access!
    return if entitlement_checker_class.new.can_access_insight?(current_user)

    redirect_to sessions_path
  end
end
