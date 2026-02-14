module Api
  module Voice
    class EventsController < ApplicationController
      skip_forgery_protection

      class_attribute :processor_class, default: ::Voice::EventProcessor

      def create
        session_record = Session.find_by(id: params[:session_id])
        return render_session_not_found unless session_record
        return render_forbidden unless authorized_for_session?(session_record)

        message = ::Voice::BridgeMessage.new(
          action: params[:event_action],
          session_id: session_record.id,
          payload: params[:payload] || {}
        )

        result = processor_class.new.call(message: message, session_record: session_record)
        if result[:success]
          render json: { success: true }
        else
          status = result[:error] == "session_not_found" ? :not_found : :unprocessable_entity
          render json: { success: false, error: result[:error] }, status: status
        end
      end

      private

      def authorized_for_session?(session_record)
        return true if valid_bridge_token_for_session?(session_record)
        return current_user.id == session_record.user_id if current_user

        request_google_sub == session_record.user.google_sub
      end

      def valid_bridge_token_for_session?(session_record)
        token = request_bridge_token
        return false if token.blank?

        payload = ::Auth::VoiceBridgeToken.verify(token: token)
        return false unless payload

        payload[:session_id] == session_record.id.to_s &&
          payload[:google_sub] == session_record.user.google_sub
      end

      def request_google_sub
        params[:google_sub].presence || params.dig(:payload, :google_sub).presence || params.dig(:payload, "google_sub").presence
      end

      def request_bridge_token
        params[:bridge_token].presence || params.dig(:payload, :bridge_token).presence || params.dig(:payload, "bridge_token").presence
      end

      def render_forbidden
        render json: { success: false, error: "forbidden" }, status: :forbidden
      end

      def render_session_not_found
        render json: { success: false, error: "session_not_found" }, status: :not_found
      end
    end
  end
end
