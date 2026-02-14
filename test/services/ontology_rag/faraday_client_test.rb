require "test_helper"

class OntologyRagFaradayClientTest < ActiveSupport::TestCase
  setup do
    @previous_base_url = ENV["ONTOLOGY_RAG_BASE_URL"]
    @previous_api_key = ENV["ONTOLOGY_RAG_API_KEY"]
    ENV["ONTOLOGY_RAG_BASE_URL"] = "https://ontology.example"
    ENV["ONTOLOGY_RAG_API_KEY"] = "sk_test_123"
  end

  teardown do
    ENV["ONTOLOGY_RAG_BASE_URL"] = @previous_base_url
    ENV["ONTOLOGY_RAG_API_KEY"] = @previous_api_key
  end

  test "P11-T1 default adapter uses Faraday request path" do
    stub_request(:post, "https://ontology.example/engine/users/identify")
      .to_return(status: 200, body: { id: "u-1", google_sub: "g-1", is_new: true }.to_json, headers: { "Content-Type" => "application/json" })

    client = OntologyRag::Client.new
    response = client.identify_user(google_sub: "g-1")

    assert_equal "u-1", response["id"]
    assert_requested :post, "https://ontology.example/engine/users/identify", times: 1
  end

  test "P11-T2 fallback handles Faraday timeout errors" do
    stub_request(:post, "https://ontology.example/engine/users/identify").to_timeout

    client = OntologyRag::Client.new(retry_attempts: 1)
    response = client.identify_user(google_sub: "g-timeout")

    assert_equal false, response["success"]
    assert_includes [ "Faraday::TimeoutError", "Faraday::ConnectionFailed" ], response["error"]
  end
end
