require "test_helper"

class E2eErrorFlowTest < ActionDispatch::IntegrationTest
  class FakeFailureClient
    def query(question:, google_sub: nil, limit: 5, container_id: nil)
      { success: false, error: "Timeout::Error", message: "timeout" }
    end
  end

  test "P43-T1 E2E ontology query upstream timeout returns 502 with error payload" do
    original = Api::OntologyRag::QueryController.client_class
    Api::OntologyRag::QueryController.client_class = FakeFailureClient

    post "/api/ontology_rag/query", params: { question: "fail case" }, as: :json

    assert_response :bad_gateway
    body = JSON.parse(response.body)
    assert_equal false, body["success"]
    assert_equal "Timeout::Error", body["error"]
  ensure
    Api::OntologyRag::QueryController.client_class = original if original
  end

  test "P43-T2 E2E voice transcription validation rejects empty payload" do
    user = User.create!(google_sub: "g-error-voice")
    session_record = Session.create!(user: user, status: "active")

    post "/api/voice/events", params: {
      event_action: "transcription",
      session_id: session_record.id,
      payload: { text: "" }
    }, as: :json

    assert_response :unprocessable_entity
    body = JSON.parse(response.body)
    assert_equal false, body["success"]
    assert_equal "empty_transcription", body["error"]
  end

  test "P43-T3 E2E subscription webhook handles unknown user with 404" do
    post "/webhooks/revenue_cat", params: {
      event_type: "INITIAL_PURCHASE",
      google_sub: "non-existent",
      revenue_cat_id: "rc_missing"
    }, as: :json

    assert_response :not_found
  end
end
