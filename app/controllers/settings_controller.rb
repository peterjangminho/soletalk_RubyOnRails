class SettingsController < ApplicationController
  before_action :authenticate_user!

  def show
    @setting = current_setting
  end

  def update
    setting = current_setting
    setting.update!(
      language: setting_params[:language],
      voice_speed: setting_params[:voice_speed],
      preferences: parsed_preferences(setting_params[:preferences_json])
    )

    redirect_to setting_path
  end

  private

  def current_setting
    current_user.settings.order(:id).last || current_user.settings.create!
  end

  def setting_params
    params.require(:setting).permit(:language, :voice_speed, :preferences_json)
  end

  def parsed_preferences(raw_json)
    return {} if raw_json.blank?

    JSON.parse(raw_json)
  rescue JSON::ParserError
    {}
  end
end
