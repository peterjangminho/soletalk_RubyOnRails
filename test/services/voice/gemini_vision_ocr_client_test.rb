require "test_helper"

module Voice
  class GeminiVisionOcrClientTest < ActiveSupport::TestCase
    test "initialization requires GEMINI_API_KEY" do
      error = assert_raises(GeminiVisionOcrClient::ConfigurationError) do
        GeminiVisionOcrClient.new(api_key: nil)
      end

      assert_includes error.message, "GEMINI_API_KEY"
    end

    test "extract_text posts inline image/pdf payload and returns candidate text" do
      captured = {}
      adapter = lambda do |request|
        captured[:request] = request
        {
          "candidates" => [
            {
              "content" => {
                "parts" => [
                  { "text" => "line1" },
                  { "text" => "line2" }
                ]
              }
            }
          ]
        }
      end

      client = GeminiVisionOcrClient.new(api_key: "gk_test", http_adapter: adapter)
      text = client.extract_text(
        raw_bytes: "hello".b,
        mime_type: "application/pdf",
        filename: "doc.pdf"
      )

      assert_equal "/v1beta/models/gemini-3-flash-preview:generateContent", captured.dig(:request, :path)
      assert_equal "gk_test", captured.dig(:request, :headers, "x-goog-api-key")
      assert_equal "application/pdf", captured.dig(:request, :body, :contents, 0, :parts, 0, :inline_data, :mime_type)
      assert_equal "line1\nline2", text
    end

    test "extract_text normalizes octet-stream mime type from file extension" do
      captured = {}
      adapter = lambda do |request|
        captured[:request] = request
        { "candidates" => [ { "content" => { "parts" => [ { "text" => "ok" } ] } } ] }
      end

      client = GeminiVisionOcrClient.new(api_key: "gk_test", http_adapter: adapter)
      client.extract_text(raw_bytes: "img".b, mime_type: "application/octet-stream", filename: "scan.jpg")

      assert_equal "image/jpeg", captured.dig(:request, :body, :contents, 0, :parts, 0, :inline_data, :mime_type)
    end

    test "extract_text rejects payload over inline request limit" do
      client = GeminiVisionOcrClient.new(api_key: "gk_test", http_adapter: ->(**) { raise "should not call adapter" })

      error = assert_raises(GeminiVisionOcrClient::OcrError) do
        client.extract_text(
          raw_bytes: ("a" * (20 * 1024 * 1024 + 1)).b,
          mime_type: "image/png",
          filename: "large.png"
        )
      end

      assert_includes error.message, "20MB"
    end
  end
end
