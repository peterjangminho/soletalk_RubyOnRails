module Auth
  class OmniauthCallbacksController < ApplicationController
    def google_oauth2
      auth_hash = request.env["omniauth.auth"] || fallback_auth_hash
      google_sub = ::Auth::GoogleSubExtractor.call(auth_hash)

      user = User.find_or_initialize_by(google_sub: google_sub)
      user.email = auth_hash.dig("info", "email")
      user.name = auth_hash.dig("info", "name")
      user.save!

      session[:user_id] = user.id
      ::OntologyRag::IdentifyUserJob.perform_later(user.google_sub)
      redirect_to root_path
    end

    def failure
      redirect_to root_path
    end

    private

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
