class HomeController < ApplicationController
  def index
    return unless current_user

    @recent_sessions = current_user.sessions.order(created_at: :desc).limit(5)
    @recent_insights = current_user.insights.order(created_at: :desc).limit(5)
  end
end
