class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_session

  def create
    @session.messages.create!(
      role: "user",
      content: message_params[:content]
    )

    redirect_to session_path(@session)
  end

  private

  def set_session
    @session = current_user.sessions.find(params[:session_id])
  end

  def message_params
    params.require(:message).permit(:content)
  end
end
