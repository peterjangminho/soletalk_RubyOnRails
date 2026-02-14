require "test_helper"

class HealthFlowTest < ActionDispatch::IntegrationTest
  test "P45-T1/P45-T3 GET /healthz returns app/db status payload with timestamp and version" do
    get "/healthz"

    assert_response :ok
    body = JSON.parse(response.body)
    assert_equal true, body["ok"]
    assert_equal "soletalk-rails", body["service"]
    assert_equal "ok", body["database"]
    assert body["timestamp"].present?
    assert body["version"].present?
  end
end
