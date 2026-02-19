require "test_helper"

module Voice
  class ContextFileIngestServiceTest < ActiveSupport::TestCase
    class FakeTextExtractor
      attr_reader :calls

      def initialize(text:, format:)
        @text = text
        @format = format
        @calls = []
      end

      def extract(uploaded_file:, raw_bytes:)
        @calls << {
          filename: uploaded_file.original_filename.to_s,
          bytes: raw_bytes.bytesize
        }

        { text: @text, format: @format }
      end
    end

    class FakeOntologyClient
      attr_reader :objects, :documents

      def initialize
        @objects = []
        @documents = []
      end

      def create_object(domain:, type:, properties:, google_sub:)
        @objects << {
          domain: domain,
          type: type,
          properties: properties,
          google_sub: google_sub
        }
        { "id" => "obj-123" }
      end

      def create_document(object_id:, content:, metadata:, auto_chunk: true)
        @documents << {
          object_id: object_id,
          content: content,
          metadata: metadata,
          auto_chunk: auto_chunk
        }

        total_chunks = metadata[:chunk_count].to_i
        total_chunks = 1 if total_chunks <= 0

        {
          "documents" => [ { "id" => "doc-1" } ],
          "vectors" => Array.new(total_chunks) { |i| { "id" => "vec-#{i}" } },
          "total_chunks" => total_chunks
        }
      end
    end

    test "P91-T2 ingests extracted text, stores text document, and sends /engine/documents payload" do
      user = User.create!(google_sub: "ingest-success-user")
      client = FakeOntologyClient.new
      extractor = FakeTextExtractor.new(text: "hello " * 400, format: "plain")
      file = build_upload(content: "binary-raw-data", filename: "notes.txt", content_type: "text/plain")

      assert_difference -> { user.context_documents.count }, 1 do
        record = ContextFileIngestService.new(
          user: user,
          uploaded_file: file,
          ontology_client: client,
          text_extractor: extractor
        ).call

        assert_equal "notes.txt", record.filename
        assert_equal "plain", record.text_format
        assert_equal "ingested", record.ingestion_status
        assert record.chunk_count.positive?
        assert_equal record.chunk_count, record.vector_count
        assert_equal(("hello " * 400).strip, record.text_content)
      end

      assert_equal 1, client.objects.length
      assert_equal 1, client.documents.length
      assert_equal "obj-123", client.documents.first[:object_id]
      assert_equal "plain", client.documents.first.dig(:metadata, :text_format)
      assert_equal "ingest-success-user", client.documents.first.dig(:metadata, :google_sub)
      assert_equal 1, extractor.calls.length
      assert_equal 0, user.reload.uploaded_files.count
    end

    test "P91-T3 stores xlsx extraction as csv text document" do
      user = User.create!(google_sub: "ingest-xlsx-user")
      client = FakeOntologyClient.new
      csv_text = "name,score\nalice,95\nbob,88"
      extractor = FakeTextExtractor.new(text: csv_text, format: "csv")
      file = build_upload(
        content: "xlsx-binary",
        filename: "sheet.xlsx",
        content_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
      )

      record = ContextFileIngestService.new(
        user: user,
        uploaded_file: file,
        ontology_client: client,
        text_extractor: extractor
      ).call

      assert_equal "csv", record.text_format
      assert_equal csv_text, record.text_content
      assert_includes record.text_content, ","
      assert_equal "csv", client.documents.first.dig(:metadata, :text_format)
    end

    test "P90-T4 rejects unsupported file type" do
      user = User.create!(google_sub: "ingest-unsupported-user")
      file = build_upload(content: "MZ", filename: "notes.exe", content_type: "application/octet-stream")

      error = assert_raises(ContextFileIngestService::IngestError) do
        ContextFileIngestService.new(user: user, uploaded_file: file).call
      end

      assert_equal "Unsupported file type", error.message
      assert_equal 0, user.context_documents.count
    end

    private

    def build_upload(content:, filename:, content_type:)
      tempfile = Tempfile.new([ "upload", File.extname(filename) ])
      tempfile.binmode
      tempfile.write(content)
      tempfile.rewind

      ActionDispatch::Http::UploadedFile.new(
        tempfile: tempfile,
        filename: filename,
        type: content_type
      )
    end
  end
end
