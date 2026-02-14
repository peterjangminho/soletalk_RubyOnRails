module Api
  module OntologyRag
    class UsersController < ApplicationController
      class_attribute :user_sync_service_class, default: ::OntologyRag::UserSyncService

      def sync
        google_sub = params[:google_sub].to_s.strip
        if google_sub.blank?
          render json: { success: false, error: "google_sub is required" }, status: :unprocessable_entity
          return
        end

        result = user_sync_service_class.new.call(google_sub: google_sub)
        if result[:success]
          render json: result, status: :ok
        else
          render json: result, status: :bad_gateway
        end
      end
    end
  end
end
