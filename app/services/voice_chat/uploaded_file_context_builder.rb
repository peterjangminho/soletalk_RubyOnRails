module VoiceChat
  class UploadedFileContextBuilder
    TEXT_CONTENT_TYPES = %w[text/plain text/csv text/markdown application/json].freeze
    MAX_PREVIEW_BYTES = 2000

    def initialize(user:)
      @user = user
    end

    def build
      attachments = @user.uploaded_files.attachments
      return { files: [], summary: "" } if attachments.empty?

      files = attachments.map { |attachment| build_file_entry(attachment) }
      summary = "#{files.length} file(s) available: #{files.map { |f| f[:filename] }.join(', ')}"

      { files: files, summary: summary }
    end

    private

    def build_file_entry(attachment)
      blob = attachment.blob
      entry = {
        filename: blob.filename.to_s,
        content_type: blob.content_type,
        byte_size: blob.byte_size
      }

      if TEXT_CONTENT_TYPES.include?(blob.content_type)
        entry[:text_preview] = extract_text_preview(blob)
      end

      entry
    end

    def extract_text_preview(blob)
      blob.download.force_encoding("UTF-8").truncate(MAX_PREVIEW_BYTES)
    rescue StandardError
      nil
    end
  end
end
