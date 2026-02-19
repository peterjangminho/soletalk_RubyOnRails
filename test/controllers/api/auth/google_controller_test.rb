require "test_helper"

module Api
  module Auth
    class GoogleControllerTest < ActionDispatch::IntegrationTest
      class FakeSuccessVerifier
        def call(id_token:)
          {
            success: true,
            sub: "native-google-sub-1",
            email: "native1@example.com",
            name: "Native One",
            picture: "https://example.com/avatar.png"
          }
        end
      end

      class FakeFailureVerifier
        def call(id_token:)
          { success: false, error: "invalid_id_token" }
        end
      end

      test "P59-T1 POST /api/auth/google/native_sign_in signs in with verified id token" do
        original = ::Api::Auth::GoogleController.id_token_verifier_class
        ::Api::Auth::GoogleController.id_token_verifier_class = FakeSuccessVerifier

        post "/api/auth/google/native_sign_in", params: { id_token: "token-1" }, as: :json

        assert_response :ok
        body = JSON.parse(response.body)
        assert_equal true, body["success"]
        assert_equal "native-google-sub-1", body["google_sub"]
        assert User.exists?(google_sub: "native-google-sub-1")

        get "/api/protected"
        assert_response :ok
      ensure
        ::Api::Auth::GoogleController.id_token_verifier_class = original if original
      end

      test "P59-T2 POST /api/auth/google/native_sign_in returns 422 when id_token missing" do
        post "/api/auth/google/native_sign_in", params: {}, as: :json

        assert_response :unprocessable_entity
        body = JSON.parse(response.body)
        assert_equal false, body["success"]
        assert_equal "id_token is required", body["error"]
      end

      test "P59-T3 POST /api/auth/google/native_sign_in returns 401 when token is invalid" do
        original = ::Api::Auth::GoogleController.id_token_verifier_class
        ::Api::Auth::GoogleController.id_token_verifier_class = FakeFailureVerifier

        post "/api/auth/google/native_sign_in", params: { id_token: "bad-token" }, as: :json

        assert_response :unauthorized
        body = JSON.parse(response.body)
        assert_equal false, body["success"]
        assert_equal "invalid_id_token", body["error"]
      ensure
        ::Api::Auth::GoogleController.id_token_verifier_class = original if original
      end

      test "P68-T3 GET /api/auth/google/mobile_handoff signs in web session with valid handoff token" do
        user = User.create!(
          google_sub: "native-handoff-sub-1",
          email: "handoff1@example.com",
          name: "Handoff One"
        )
        token = ::Auth::MobileSessionHandoffToken.generate(
          user_id: user.id,
          google_sub: user.google_sub,
          expires_in: 10.minutes
        )

        get "/api/auth/google/mobile_handoff", params: { handoff: token }

        assert_response :redirect
        assert_redirected_to "/"

        get "/api/protected"
        assert_response :ok
      end

      test "P68-T4 GET /api/auth/google/mobile_handoff redirects to root when token invalid" do
        get "/api/auth/google/mobile_handoff", params: { handoff: "bad-token" }

        assert_response :redirect
        assert_redirected_to "/"

        get "/api/protected"
        assert_response :redirect
      end
    end
  end
end
