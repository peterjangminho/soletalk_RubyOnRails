require "test_helper"

module Api
  module OntologyRag
    class UsersControllerTest < ActionDispatch::IntegrationTest
      class FakeSuccessService
        def call(google_sub:)
          { success: true, user_id: "u-1", google_sub: google_sub, is_new: true }
        end
      end

      class FakeFailureService
        def call(google_sub:)
          { success: false, error: "Timeout::Error", message: "timeout for #{google_sub}" }
        end
      end

      setup do
        @previous_service_class = ::Api::OntologyRag::UsersController.user_sync_service_class
      end

      teardown do
        ::Api::OntologyRag::UsersController.user_sync_service_class = @previous_service_class
      end

      test "P5-T1 POST /api/ontology_rag/users/sync returns success payload" do
        ::Api::OntologyRag::UsersController.user_sync_service_class = FakeSuccessService

        post "/api/ontology_rag/users/sync", params: { google_sub: "g-1" }

        assert_response :ok
        body = JSON.parse(response.body)

        assert_equal true, body["success"]
        assert_equal "u-1", body["user_id"]
        assert_equal "g-1", body["google_sub"]
      end

      test "P5-T2 POST /api/ontology_rag/users/sync returns 422 when google_sub missing" do
        post "/api/ontology_rag/users/sync", params: {}

        assert_response :unprocessable_entity
        body = JSON.parse(response.body)

        assert_equal false, body["success"]
        assert_equal "google_sub is required", body["error"]
      end

      test "P5-T3 POST /api/ontology_rag/users/sync returns 502 on upstream failure" do
        ::Api::OntologyRag::UsersController.user_sync_service_class = FakeFailureService

        post "/api/ontology_rag/users/sync", params: { google_sub: "g-2" }

        assert_response :bad_gateway
        body = JSON.parse(response.body)

        assert_equal false, body["success"]
        assert_equal "Timeout::Error", body["error"]
      end
    end
  end
end
