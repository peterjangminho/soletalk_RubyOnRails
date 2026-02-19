module Dev
  class SessionsController < ApplicationController
    def create
      user = find_or_create_dev_user
      session[:user_id] = user.id

      redirect_to root_path, notice: t("flash.dev.sign_in.notice")
    end

    def destroy
      reset_session
      redirect_to root_path, notice: t("flash.dev.sign_out.notice")
    end

    private

    def find_or_create_dev_user
      google_sub = params[:google_sub].presence || "dev-mobile-user"
      user = User.find_or_initialize_by(google_sub: google_sub)
      user.name ||= "Dev Mobile User"
      user.email ||= "#{google_sub}@local.dev"
      user.save!
      user
    end
  end
end
