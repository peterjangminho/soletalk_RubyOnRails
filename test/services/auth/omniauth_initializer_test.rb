require "test_helper"

class OmniauthInitializerTest < ActiveSupport::TestCase
  test "P10-T1 omniauth middleware is registered" do
    middleware = Rails.application.middleware.map(&:klass)
    assert_includes middleware, OmniAuth::Builder
  end
end
