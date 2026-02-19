require "securerandom"

module Auth
  class GuestSessionsController < ApplicationController
    def create
      session[:policy_agreed] = true if params[:consent_accepted] == "1"
      user = build_guest_user
      session[:user_id] = user.id

      redirect_to root_path
    end

    private

    def build_guest_user
      loop do
        candidate = User.new(
          google_sub: "guest-#{SecureRandom.hex(10)}",
          name: "Guest User"
        )
        return candidate.tap(&:save!) if candidate.valid?
      end
    end
  end
end
