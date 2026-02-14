class SubscriptionController < ApplicationController
  before_action :authenticate_user!

  class_attribute :subscription_sync_service_class, default: Subscription::SyncService

  def show
    @user = current_user
  end

  def validate
    current_user.update!(revenue_cat_id: params[:revenue_cat_id]) if params[:revenue_cat_id].present?
    subscription_sync_service_class.new.call(user: current_user)

    redirect_to subscription_path
  end
end
