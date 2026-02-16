class SubscriptionController < ApplicationController
  before_action :authenticate_user!

  class_attribute :subscription_sync_service_class, default: Subscription::SyncService

  def show
    redirect_to setting_path(anchor: "subscription")
  end

  def validate
    revenue_cat_id = params[:revenue_cat_id].to_s.strip
    current_user.update!(revenue_cat_id: revenue_cat_id) if revenue_cat_id.present?
    result = begin
      subscription_sync_service_class.new.call(user: current_user)
    rescue Subscription::RevenueCatClient::ConfigurationError
      return redirect_to setting_path(anchor: "subscription"), alert: t("flash.subscription.validate.errors.configuration_missing")
    end

    unless result[:success]
      error_key = "flash.subscription.validate.errors.#{result[:error]}"
      return redirect_to setting_path(anchor: "subscription"), alert: t(error_key, default: t("flash.subscription.validate.errors.default"))
    end

    redirect_to setting_path(anchor: "subscription"), notice: t("flash.subscription.validate.notice")
  end
end
