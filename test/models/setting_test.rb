require "test_helper"

class SettingTest < ActiveSupport::TestCase
  test "P8-T3 belongs_to user and sets defaults" do
    user = User.create!(google_sub: "g-setting", email: "set@example.com")
    setting = Setting.create!(user: user)

    assert_equal "ko", setting.language
    assert_in_delta 1.0, setting.voice_speed, 0.001
    assert_equal({}, setting.preferences)
  end
end
