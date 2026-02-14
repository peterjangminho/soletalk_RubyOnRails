module Api
  class ProtectedController < ApplicationController
    before_action :authenticate_user!

    def show
      render json: { success: true, user_id: current_user.id }
    end
  end
end
