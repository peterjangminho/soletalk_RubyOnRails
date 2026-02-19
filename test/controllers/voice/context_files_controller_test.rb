require "test_helper"

module Voice
  class ContextFilesControllerTest < ActionDispatch::IntegrationTest
    def sign_in(google_sub:)
      OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
        provider: "google_oauth2", uid: google_sub,
        info: { email: "#{google_sub}@example.com", name: "Test User" }
      )
      get "/auth/google_oauth2/callback"
      follow_redirect!
    end

    test "POST /voice/context_files redirects unauthenticated" do
      post "/voice/context_files"

      assert_response :redirect
      assert_redirected_to "/"
    end

    test "POST /voice/context_files without file returns 422" do
      sign_in(google_sub: "ctx-no-file-user")

      post "/voice/context_files", params: {}, as: :json

      assert_response :unprocessable_entity
      body = JSON.parse(response.body)
      assert_equal "error", body["status"]
      assert_equal "No file provided", body["message"]
    end

    test "POST /voice/context_files with file attaches and returns ok" do
      sign_in(google_sub: "ctx-upload-user")
      user = User.find_by!(google_sub: "ctx-upload-user")

      tempfile = Tempfile.new(["test", ".txt"])
      tempfile.write("test content")
      tempfile.rewind

      file = Rack::Test::UploadedFile.new(tempfile.path, "text/plain", false, original_filename: "test.txt")

      assert_difference -> { user.uploaded_files.count }, 1 do
        post "/voice/context_files", params: { file: file }
      end

      assert_response :ok
      body = JSON.parse(response.body)
      assert_equal "ok", body["status"]
      assert_equal "test.txt", body["filename"]
    ensure
      tempfile&.close
      tempfile&.unlink
    end
  end
end
