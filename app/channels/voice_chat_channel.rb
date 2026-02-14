class VoiceChatChannel < ApplicationCable::Channel
  ALLOWED_RECEIVE_KEYS = %w[message phase emotion_level timestamp].freeze

  def subscribed
    @session = Session.find_by(id: params[:session_id])
    unless @session
      reject
      return
    end

    stream_from(stream_name(@session.id))
  end

  def receive(data)
    return unless @session

    ActionCable.server.broadcast(
      stream_name(@session.id),
      data.slice(*ALLOWED_RECEIVE_KEYS)
    )
  end

  def replay(data)
    return unless @session

    last_message_id = data["last_message_id"].to_i
    messages = @session.messages.where("id > ?", last_message_id).order(:id).limit(50)
    current_phase = @session.voice_chat_data&.current_phase || "opener"

    ActionCable.server.broadcast(
      stream_name(@session.id),
      {
        type: "replay",
        session_id: @session.id,
        current_phase: current_phase,
        messages: messages.map do |message|
          {
            id: message.id,
            role: message.role,
            content: message.content,
            created_at: message.created_at.iso8601
          }
        end
      }
    )
  end

  private

  def stream_name(session_id)
    "voice_chat:#{session_id}"
  end
end
