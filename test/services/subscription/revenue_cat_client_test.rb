require "test_helper"

module Subscription
  class RevenueCatClientTest < ActiveSupport::TestCase
    class FakeAdapter
      cattr_accessor :response_payload

      def call(path:, method:, headers:, body:, params:, open_timeout:, read_timeout:)
        {
          "path" => path,
          "method" => method,
          "headers" => headers,
          "payload" => self.class.response_payload
        }
      end
    end

    test "P34-T1 validates required env configuration" do
      assert_raises(Subscription::RevenueCatClient::ConfigurationError) do
        Subscription::RevenueCatClient.new(base_url: nil, api_key: "key")
      end

      assert_raises(Subscription::RevenueCatClient::ConfigurationError) do
        Subscription::RevenueCatClient.new(base_url: "https://api.revenuecat.com", api_key: nil)
      end
    end

    test "P34-T2 normalizes subscriber entitlement payload" do
      FakeAdapter.response_payload = {
        "subscriber" => {
          "entitlements" => {
            "premium_access" => {
              "expires_date" => 3.days.from_now.iso8601
            }
          }
        }
      }

      client = Subscription::RevenueCatClient.new(
        base_url: "https://api.revenuecat.com",
        api_key: "rc-key",
        http_adapter: FakeAdapter.new
      )

      result = client.fetch_subscriber(revenue_cat_id: "rc_abc")

      assert_equal true, result[:premium]
      assert result[:expires_at].present?
      assert_equal "/v1/subscribers/rc_abc", result[:raw]["path"]
    end
  end
end
