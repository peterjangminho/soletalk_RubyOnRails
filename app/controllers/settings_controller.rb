class SettingsController < ApplicationController
  before_action :authenticate_user!

  def show
    @setting = current_setting
  end

  def update
    setting = current_setting
    preferences = parsed_preferences(setting_params[:preferences_json])
    if preferences == :invalid
      redirect_to setting_path, alert: t("flash.settings.update.invalid_json")
      return
    end

    setting.update!(
      language: setting_params[:language],
      voice_speed: setting_params[:voice_speed],
      preferences: preferences
    )
    attach_uploaded_file!

    redirect_to setting_path, notice: t("flash.settings.update.notice")
  end

  private

  def current_setting
    current_user.settings.order(:id).last || current_user.settings.create!
  end

  def setting_params
    params.require(:setting).permit(:language, :voice_speed, :preferences_json, :uploaded_file)
  end

  def parsed_preferences(raw_json)
    return {} if raw_json.blank?

    JSON.parse(raw_json)
  rescue JSON::ParserError
    :invalid
  end

  def attach_uploaded_file!
    uploaded_file = setting_params[:uploaded_file]
    return if uploaded_file.blank?

    current_user.uploaded_files.attach(uploaded_file)
  end
end
