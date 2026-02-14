require "test_helper"

class OntologyRagUserSyncServiceTest < ActiveSupport::TestCase
  class StubClient
    attr_reader :received_google_sub

    def initialize(response)
      @response = response
    end

    def identify_user(google_sub:)
      @received_google_sub = google_sub
      @response
    end
  end

  test "P4-T1 identifies user and returns standardized success payload" do
    client = StubClient.new({ "id" => "u-1", "google_sub" => "g-1", "is_new" => true })

    service = OntologyRag::UserSyncService.new(client: client)
    result = service.call(google_sub: "g-1")

    assert_equal "g-1", client.received_google_sub
    assert_equal true, result[:success]
    assert_equal "u-1", result[:user_id]
    assert_equal "g-1", result[:google_sub]
    assert_equal true, result[:is_new]
  end

  test "P4-T2 returns standardized error payload on failed upstream response" do
    client = StubClient.new({ "success" => false, "error" => "Timeout::Error", "message" => "timeout" })

    service = OntologyRag::UserSyncService.new(client: client)
    result = service.call(google_sub: "g-2")

    assert_equal false, result[:success]
    assert_equal "Timeout::Error", result[:error]
    assert_equal "timeout", result[:message]
  end
end
