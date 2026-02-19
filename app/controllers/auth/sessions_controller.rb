module Auth
  class SessionsController < ApplicationController
    def destroy
      reset_session
      redirect_to root_path, notice: t("flash.auth.sign_out.notice")
    end
  end
end
