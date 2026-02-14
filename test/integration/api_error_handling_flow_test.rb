require "test_helper"

class ApiErrorHandlingFlowTest < ActionDispatch::IntegrationTest
  class FakeReporter
    cattr_accessor :payload

    def report(exception:, context:)
      self.class.payload = {
        exception_class: exception.class.name,
        context: context
      }
    end
  end

  class FakeRaiseClient
    def query(question:, google_sub: nil, limit: 5, container_id: nil)
      raise RuntimeError, "boom"
    end
  end

  test "P46-T1/P46-T3 API unexpected exception returns standardized 500 and reports error" do
    original_client = Api::OntologyRag::QueryController.client_class
    original_reporter = ApplicationController.error_reporter_class
    Api::OntologyRag::QueryController.client_class = FakeRaiseClient
    ApplicationController.error_reporter_class = FakeReporter
    FakeReporter.payload = nil

    post "/api/ontology_rag/query", params: { question: "trigger exception" }, as: :json

    assert_response :internal_server_error
    body = JSON.parse(response.body)
    assert_equal false, body["success"]
    assert_equal "internal_error", body["error"]
    assert body["request_id"].present?
    assert_equal "RuntimeError", FakeReporter.payload[:exception_class]
  ensure
    Api::OntologyRag::QueryController.client_class = original_client if original_client
    ApplicationController.error_reporter_class = original_reporter if original_reporter
  end

  test "P46-T2 ActiveRecord::RecordNotFound returns standardized 404 payload" do
    post "/webhooks/revenue_cat", params: {
      event_type: "INITIAL_PURCHASE",
      google_sub: "missing-user"
    }, as: :json

    assert_response :not_found
    body = JSON.parse(response.body)
    assert_equal false, body["success"]
    assert_equal "not_found", body["error"]
  end
end
