class InsightsController < ApplicationController
  before_action :authenticate_user!
  before_action :redirect_to_voice_home

  class_attribute :entitlement_checker_class, default: Subscription::EntitlementChecker

  def index
    @insights = current_user.insights.order(created_at: :desc)
  end

  def show
    @insight = current_user.insights.find(params[:id])
  end

  private

  def redirect_to_voice_home
    redirect_to root_path
  end
end
