class SessionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_session, only: :show

  def index
    @sessions = current_user.sessions.order(created_at: :desc)
  end

  def new
    @session = current_user.sessions.new
  end

  def create
    @session = current_user.sessions.create!(status: "active")
    VoiceChatData.create!(session: @session, current_phase: "opener")
    redirect_to session_path(@session)
  end

  def show
    @voice_chat_data = @session.voice_chat_data
    @recent_insights = Insight.order(created_at: :desc).limit(3)
  end

  private

  def set_session
    @session = current_user.sessions.find(params[:id])
  end
end
