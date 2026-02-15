require "test_helper"

class OmniauthInitializerTest < ActiveSupport::TestCase
  test "P10-T1 omniauth middleware is registered" do
    middleware = Rails.application.middleware.map(&:klass)
    assert_includes middleware, OmniAuth::Builder
  end

  test "P10-T4 omniauth allows get and post request methods for provider entrypoint" do
    assert_includes OmniAuth.config.allowed_request_methods, :get
    assert_includes OmniAuth.config.allowed_request_methods, :post
  end
end
