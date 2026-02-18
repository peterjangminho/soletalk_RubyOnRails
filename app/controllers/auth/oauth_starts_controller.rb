module Auth
  class OauthStartsController < ApplicationController
    MOBILE_RETURN_PARAM = "mobile_return".freeze
    MOBILE_RETURN_SESSION_KEY = :mobile_return_uri

    def google_oauth2
      session.delete(MOBILE_RETURN_SESSION_KEY)
      accept_inline_consent
      normalized_mobile_return = ::Auth::MobileOauthReturnUri.normalize(params[MOBILE_RETURN_PARAM])
      if normalized_mobile_return.present?
        session[MOBILE_RETURN_SESSION_KEY] = normalized_mobile_return
        redirect_to "/auth/google_oauth2"
        return
      end

      unless session[:policy_agreed] == true
        redirect_to consent_path, alert: "Please review and agree to the policy before sign in."
        return
      end

      redirect_to "/auth/google_oauth2"
    end

    private

    def accept_inline_consent
      session[:policy_agreed] = true if params[:consent_accepted] == "1"
    end
  end
end
