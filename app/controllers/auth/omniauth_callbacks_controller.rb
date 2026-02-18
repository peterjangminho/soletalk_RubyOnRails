require "cgi"

module Auth
  class OmniauthCallbacksController < ApplicationController
    MOBILE_RETURN_PARAM = "mobile_return".freeze
    MOBILE_RETURN_SESSION_KEY = :mobile_return_uri

    def google_oauth2
      auth_hash = request.env["omniauth.auth"] || fallback_auth_hash
      google_sub = ::Auth::GoogleSubExtractor.call(auth_hash)

      user = User.find_or_initialize_by(google_sub: google_sub)
      user.email = auth_hash.dig("info", "email")
      user.name = auth_hash.dig("info", "name")
      user.save!

      session[:user_id] = user.id
      ::OntologyRag::IdentifyUserJob.perform_later(user.google_sub)

      mobile_return_uri = safe_mobile_return_uri
      if mobile_return_uri.present?
        handoff = ::Auth::MobileSessionHandoffToken.generate(
          user_id: user.id,
          google_sub: user.google_sub
        )
        redirect_to "#{mobile_return_uri}?handoff=#{CGI.escape(handoff)}", allow_other_host: true
      else
        redirect_to root_path
      end
    end

    def failure
      redirect_to root_path, alert: t("flash.auth.failure")
    end

    private

    def safe_mobile_return_uri
      from_params = params[MOBILE_RETURN_PARAM].presence || request.env.dig("omniauth.params", MOBILE_RETURN_PARAM).presence
      normalized = ::Auth::MobileOauthReturnUri.normalize(from_params)
      return normalized if normalized.present?

      ::Auth::MobileOauthReturnUri.normalize(session.delete(MOBILE_RETURN_SESSION_KEY))
    end

    def fallback_auth_hash
      {
        "uid" => params[:uid],
        "info" => {
          "email" => params[:email],
          "name" => params[:name]
        }
      }
    end
  end
end
