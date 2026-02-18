module Api
  module Auth
    class GoogleController < ApplicationController
      class_attribute :id_token_verifier_class, default: ::Auth::GoogleIdTokenVerifier
      class_attribute :mobile_handoff_token_class, default: ::Auth::MobileSessionHandoffToken

      def native_sign_in
        id_token = params[:id_token].to_s.strip
        if id_token.blank?
          render json: { success: false, error: "id_token is required" }, status: :unprocessable_entity
          return
        end

        result = id_token_verifier_class.new.call(id_token: id_token)
        unless result[:success]
          render json: { success: false, error: result[:error] || "invalid_id_token" }, status: :unauthorized
          return
        end

        user = User.find_or_initialize_by(google_sub: result[:sub])
        user.email = result[:email]
        user.name = result[:name]
        user.avatar_url = result[:picture]
        user.save!

        session[:user_id] = user.id
        ::OntologyRag::IdentifyUserJob.perform_later(user.google_sub)

        render json: {
          success: true,
          user_id: user.id,
          google_sub: user.google_sub
        }, status: :ok
      end

      def mobile_handoff
        token = params[:handoff].to_s
        payload = mobile_handoff_token_class.verify(token: token)
        user = find_user_for_payload(payload)

        if user.nil?
          redirect_to root_path, alert: t("flash.auth.failure")
          return
        end

        session[:user_id] = user.id
        redirect_to root_path
      end

      private

      def find_user_for_payload(payload)
        return nil if payload.nil?

        User.find_by(id: payload[:user_id], google_sub: payload[:google_sub])
      end
    end
  end
end
