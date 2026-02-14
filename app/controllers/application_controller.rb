class ApplicationController < ActionController::Base
  helper_method :current_user
  class_attribute :error_reporter_class, default: Ops::ErrorReporter

  rescue_from StandardError, with: :render_internal_error
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  private

  def current_user
    return nil unless session[:user_id]

    @current_user ||= User.find_by(id: session[:user_id])
  end

  def authenticate_user!
    redirect_to root_path unless current_user
  end

  def render_not_found(error)
    if request.format.json?
      render json: { success: false, error: "not_found" }, status: :not_found
    else
      render plain: "not found", status: :not_found
    end
  end

  def render_internal_error(error)
    error_reporter_class.new.report(
      exception: error,
      context: {
        path: request.fullpath,
        request_id: request.request_id
      }
    )

    if request.format.json?
      render json: { success: false, error: "internal_error", request_id: request.request_id }, status: :internal_server_error
    else
      raise error if Rails.env.development? || Rails.env.test?

      render plain: "internal server error", status: :internal_server_error
    end
  end
end
