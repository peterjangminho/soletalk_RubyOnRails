class OnboardingController < ApplicationController
  def signup
    @pending_name = session[:pending_signup_name].to_s
    @pending_email = session[:pending_signup_email].to_s
  end

  def create_signup
    session[:pending_signup_name] = params[:name].to_s.strip
    session[:pending_signup_email] = params[:email].to_s.strip
    redirect_to consent_path
  end

  def consent
    @pending_name = session[:pending_signup_name].to_s
    @pending_email = session[:pending_signup_email].to_s
  end

  def accept_consent
    unless params[:agree] == "1"
      redirect_to consent_path, alert: "Please agree to continue."
      return
    end

    session[:policy_agreed] = true
    redirect_to root_path, notice: "Consent completed. You can continue with sign in."
  end
end
