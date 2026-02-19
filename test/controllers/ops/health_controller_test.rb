require "test_helper"

module Ops
  class HealthControllerTest < ActionDispatch::IntegrationTest
    def sign_in(google_sub:)
      OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
        provider: "google_oauth2", uid: google_sub,
        info: { email: "#{google_sub}@example.com", name: "Test User" }
      )
      get "/auth/google_oauth2/callback"
      follow_redirect!
    end

    test "GET /healthz returns ok JSON without auth" do
      get "/healthz"

      assert_response :ok
      body = JSON.parse(response.body)
      assert_equal true, body["ok"]
    end

    test "GET /healthz includes service name and version" do
      get "/healthz"

      assert_response :ok
      body = JSON.parse(response.body)
      assert_equal "soletalk-rails", body["service"]
      assert_not_nil body["version"]
      assert_not_nil body["timestamp"]
    end

    test "GET /healthz includes database status" do
      get "/healthz"

      assert_response :ok
      body = JSON.parse(response.body)
      assert_equal "ok", body["database"]
    end
  end
end
