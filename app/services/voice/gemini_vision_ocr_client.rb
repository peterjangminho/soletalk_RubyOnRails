require "base64"
require "faraday"
require "json"

module Voice
  class GeminiVisionOcrClient
    class ConfigurationError < StandardError; end
    class OcrError < StandardError; end

    DEFAULT_MODEL = "gemini-3-flash-preview"
    DEFAULT_TIMEOUT = 20
    INLINE_BYTES_LIMIT = 20 * 1024 * 1024

    def initialize(api_key: ENV.fetch("GEMINI_API_KEY", nil), model: DEFAULT_MODEL, timeout: DEFAULT_TIMEOUT, http_adapter: nil)
      raise ConfigurationError, "Missing GEMINI_API_KEY" if api_key.blank?

      @api_key = api_key
      @model = model
      @timeout = timeout
      @http_adapter = http_adapter
    end

    def extract_text(raw_bytes:, mime_type:, filename: nil)
      raise OcrError, "File too large for inline Gemini Vision request (max 20MB)" if raw_bytes.bytesize > INLINE_BYTES_LIMIT

      payload = {
        contents: [
          {
            parts: [
              {
                inline_data: {
                  mime_type: normalized_mime_type(mime_type: mime_type, filename: filename),
                  data: Base64.strict_encode64(raw_bytes)
                }
              },
              { text: prompt(filename: filename) }
            ]
          }
        ],
        generationConfig: {
          temperature: 0,
          maxOutputTokens: 8192
        }
      }

      response = adapter.call(
        path: request_path,
        body: payload,
        timeout: @timeout,
        headers: request_headers
      )
      text = extract_response_text(response)
      raise OcrError, "Gemini OCR returned empty text" if text.blank?

      text
    rescue OcrError
      raise
    rescue StandardError => e
      raise OcrError, "Gemini OCR failed: #{e.message}"
    end

    private

    def adapter
      @http_adapter || method(:default_http_adapter)
    end

    def default_http_adapter(path:, body:, timeout:, headers:)
      connection(timeout: timeout).post(path) do |request|
        request.headers.update(headers)
        request.body = body
      end.body
    end

    def connection(timeout:)
      Faraday.new(url: "https://generativelanguage.googleapis.com") do |faraday|
        faraday.options.timeout = timeout
        faraday.options.open_timeout = timeout
        faraday.request :json
        faraday.response :json, content_type: /\bjson$/
        faraday.adapter Faraday.default_adapter
      end
    end

    def request_path
      "/v1beta/models/#{@model}:generateContent"
    end

    def request_headers
      {
        "Content-Type" => "application/json",
        "x-goog-api-key" => @api_key
      }
    end

    def prompt(filename:)
      target = filename.presence || "uploaded file"
      <<~PROMPT.squish
        Extract all readable text from #{target}. Preserve original order and line breaks.
        If the document is tabular, output as CSV text only. Do not add commentary.
      PROMPT
    end

    def normalized_mime_type(mime_type:, filename:)
      type = mime_type.to_s
      return type if type.present? && type != "application/octet-stream"

      extension = File.extname(filename.to_s).downcase
      return "application/pdf" if extension == ".pdf"
      return "image/png" if extension == ".png"
      return "image/jpeg" if %w[.jpg .jpeg].include?(extension)
      return "image/webp" if extension == ".webp"
      return "image/heic" if extension == ".heic"
      return "image/heif" if extension == ".heif"

      "application/octet-stream"
    end

    def extract_response_text(response)
      candidates = response["candidates"]
      return nil unless candidates.is_a?(Array)

      first = candidates.first || {}
      parts = first.dig("content", "parts")
      return nil unless parts.is_a?(Array)

      parts.map { |part| part["text"] }.compact.join("\n").strip
    end
  end
end
