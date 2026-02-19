require "digest"

module Voice
  class ContextFileIngestService
    class IngestError < StandardError; end

    MAX_FILE_SIZE_BYTES = 10 * 1024 * 1024
    TEXT_CONTENT_TYPES = %w[text/plain text/csv text/markdown application/json].freeze
    EXCEL_CONTENT_TYPES = [
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    ].freeze
    OCR_CONTENT_TYPES = %w[application/pdf image/png image/jpeg image/jpg image/webp image/heic image/heif].freeze
    SUPPORTED_CONTENT_TYPES = (TEXT_CONTENT_TYPES + EXCEL_CONTENT_TYPES + OCR_CONTENT_TYPES).freeze

    CHUNK_SIZE = 1_200
    CHUNK_OVERLAP = 200

    OBJECT_DOMAIN = "context_file".freeze
    OBJECT_TYPE = "uploaded_reference".freeze

    def initialize(user:, uploaded_file:, ontology_client: nil, text_extractor: nil)
      @user = user
      @uploaded_file = uploaded_file
      @ontology_client = ontology_client
      @text_extractor = text_extractor
    end

    def call
      validate_file!

      raw_bytes = @uploaded_file.read
      @uploaded_file.rewind

      source_checksum = Digest::SHA256.hexdigest(raw_bytes)
      extracted = text_extractor.extract(uploaded_file: @uploaded_file, raw_bytes: raw_bytes)
      normalized_text = extracted.fetch(:text).to_s.strip
      text_format = extracted.fetch(:format, "plain").to_s

      raise IngestError, "No text content extracted from file" if normalized_text.blank?

      chunk_count = chunk_text(normalized_text).length
      object_id = create_ontology_object(source_checksum: source_checksum, chunk_count: chunk_count, text_format: text_format)
      ingest_response = ingest_document(
        object_id: object_id,
        source_checksum: source_checksum,
        text: normalized_text,
        chunk_count: chunk_count,
        text_format: text_format
      )
      vector_count = vector_count_for(ingest_response, fallback_count: chunk_count)

      ContextDocument.create!(
        user: @user,
        filename: @uploaded_file.original_filename.to_s,
        content_type: @uploaded_file.content_type.to_s,
        byte_size: @uploaded_file.size.to_i,
        source_checksum: source_checksum,
        chunk_count: chunk_count,
        vector_count: vector_count,
        ontology_object_id: object_id,
        storage_mode: "text_document_local_and_remote_embedding",
        ingestion_status: "ingested",
        text_content: normalized_text,
        text_format: text_format,
        metadata: {
          ingested_at: Time.current.iso8601,
          ontology_total_chunks: ingest_response["total_chunks"],
          ontology_document_ids: extract_document_ids(ingest_response)
        }
      )
    rescue IngestError
      raise
    rescue StandardError => e
      raise IngestError, e.message
    end

    private

    def validate_file!
      raise IngestError, "No file provided" if @uploaded_file.blank?
      raise IngestError, "Unsupported file type" unless supported_content_type?
      raise IngestError, "File is too large" if @uploaded_file.size.to_i > MAX_FILE_SIZE_BYTES
    end

    def supported_content_type?
      content_type = @uploaded_file.content_type.to_s
      return true if SUPPORTED_CONTENT_TYPES.include?(content_type)
      return true if content_type.start_with?("text/")
      return true if excel_file_extension?

      false
    end

    def excel_file_extension?
      File.extname(@uploaded_file.original_filename.to_s).casecmp(".xlsx").zero?
    end

    def chunk_text(text)
      return [] if text.blank?

      chunks = []
      cursor = 0
      stride = CHUNK_SIZE - CHUNK_OVERLAP

      while cursor < text.length
        chunk = text[cursor, CHUNK_SIZE].to_s.strip
        chunks << chunk if chunk.present?
        cursor += stride
      end

      chunks
    end

    def create_ontology_object(source_checksum:, chunk_count:, text_format:)
      response = ontology_client.create_object(
        domain: OBJECT_DOMAIN,
        type: OBJECT_TYPE,
        google_sub: @user.google_sub,
        properties: {
          filename: @uploaded_file.original_filename.to_s,
          content_type: @uploaded_file.content_type.to_s,
          byte_size: @uploaded_file.size.to_i,
          source_checksum: source_checksum,
          chunk_count: chunk_count,
          text_format: text_format
        }
      )

      object_id = response["id"] || response.dig("object", "id")
      raise IngestError, "OntologyRAG object id missing" if object_id.blank?

      object_id
    end

    def ingest_document(object_id:, source_checksum:, text:, chunk_count:, text_format:)
      ontology_client.create_document(
        object_id: object_id,
        content: text,
        auto_chunk: true,
        metadata: {
          filename: @uploaded_file.original_filename.to_s,
          source_checksum: source_checksum,
          chunk_count: chunk_count,
          text_format: text_format,
          google_sub: @user.google_sub
        }
      )
    end

    def extract_document_ids(response)
      documents = response["documents"]
      return [] unless documents.is_a?(Array)

      documents.map { |doc| doc["id"] }.compact
    end

    def vector_count_for(response, fallback_count:)
      return response["vectors"].length if response["vectors"].is_a?(Array)
      return response["total_chunks"].to_i if response["total_chunks"].to_i.positive?
      return response["vector_count"].to_i if response["vector_count"].to_i.positive?

      fallback_count
    end

    def ontology_client
      return @ontology_client if @ontology_client
      return @ontology_client = NullOntologyClient.new if Rails.env.test?

      @ontology_client = OntologyRag::Client.new
    end

    def text_extractor
      @text_extractor ||= ContextTextExtractor.new
    end

    class NullOntologyClient
      def create_object(**)
        { "id" => "test-object-id" }
      end

      def create_document(**)
        {
          "documents" => [ { "id" => "test-document-id" } ],
          "vectors" => [ { "id" => "test-vector-id" } ],
          "total_chunks" => 1
        }
      end
    end
  end
end
