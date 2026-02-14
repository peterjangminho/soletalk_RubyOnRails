require "test_helper"

module Api
  module OntologyRag
    class QueryControllerTest < ActionDispatch::IntegrationTest
      class FakeSuccessClient
        def query(question:, google_sub: nil, limit: 5, container_id: nil)
          {
            answer: "answer for #{question}",
            context: "ctx",
            sources: [ { id: "s1", score: 0.9 } ],
            query: question
          }
        end
      end

      class FakeFailureClient
        def query(question:, google_sub: nil, limit: 5, container_id: nil)
          { success: false, error: "Timeout::Error", message: "upstream timeout" }
        end
      end

      test "P40-T1 POST /api/ontology_rag/query validates required question param" do
        post "/api/ontology_rag/query", params: {}, as: :json

        assert_response :unprocessable_entity
        body = JSON.parse(response.body)
        assert_equal false, body["success"]
      end

      test "P40-T2 POST /api/ontology_rag/query returns normalized query response" do
        original = ::Api::OntologyRag::QueryController.client_class
        ::Api::OntologyRag::QueryController.client_class = FakeSuccessClient

        post "/api/ontology_rag/query", params: { question: "what now?", google_sub: "g-1" }, as: :json

        assert_response :ok
        body = JSON.parse(response.body)
        assert_equal true, body["success"]
        assert_equal "answer for what now?", body["answer"]
        assert_equal "what now?", body["query"]
      ensure
        ::Api::OntologyRag::QueryController.client_class = original if original
      end

      test "P40-T3 POST /api/ontology_rag/query propagates upstream error as 502" do
        original = ::Api::OntologyRag::QueryController.client_class
        ::Api::OntologyRag::QueryController.client_class = FakeFailureClient

        post "/api/ontology_rag/query", params: { question: "what now?" }, as: :json

        assert_response :bad_gateway
        body = JSON.parse(response.body)
        assert_equal false, body["success"]
        assert_equal "Timeout::Error", body["error"]
      ensure
        ::Api::OntologyRag::QueryController.client_class = original if original
      end
    end
  end
end
