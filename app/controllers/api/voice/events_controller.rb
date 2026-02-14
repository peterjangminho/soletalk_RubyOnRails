module Api
  module Voice
    class EventsController < ApplicationController
      skip_forgery_protection

      class_attribute :processor_class, default: ::Voice::EventProcessor

      def create
        message = ::Voice::BridgeMessage.new(
          action: params[:event_action],
          session_id: params[:session_id],
          payload: params[:payload] || {}
        )

        result = processor_class.new.call(message: message)
        if result[:success]
          render json: { success: true }
        else
          render json: { success: false, error: result[:error] }, status: :unprocessable_entity
        end
      end
    end
  end
end
