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
    ActiveRecord::Base.transaction do
      @session = current_user.sessions.create!(status: "active")
      VoiceChatData.create!(session: @session, current_phase: "opener")
    end
    redirect_to session_redirect_path, notice: t("flash.sessions.create.notice")
  rescue ActiveRecord::RecordInvalid
    redirect_to new_session_path, alert: t("flash.sessions.create.alert")
  end

  def show
    @voice_chat_data = @session.voice_chat_data
    @recent_insights = current_user.insights.order(created_at: :desc).limit(3)
    @bridge_token = ::Auth::VoiceBridgeToken.generate(
      session_id: @session.id,
      google_sub: current_user.google_sub
    )
  end

  private

  def set_session
    @session = current_user.sessions.find(params[:id])
  end

  def session_redirect_path
    return session_path(@session, auto_start_recording: "1") if params[:entrypoint] == "main_mic"

    session_path(@session)
  end
end
