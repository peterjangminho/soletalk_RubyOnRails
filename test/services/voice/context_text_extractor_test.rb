require "test_helper"
require "zip"

module Voice
  class ContextTextExtractorTest < ActiveSupport::TestCase
    class FakeOcrClient
      attr_reader :calls

      def initialize(output:)
        @output = output
        @calls = []
      end

      def extract_text(raw_bytes:, mime_type:, filename:)
        @calls << {
          bytes: raw_bytes.bytesize,
          mime_type: mime_type,
          filename: filename
        }
        @output
      end
    end

    test "extract keeps plain text as-is" do
      extractor = ContextTextExtractor.new
      file = build_upload(
        content: "hello world",
        filename: "notes.txt",
        content_type: "text/plain"
      )

      result = extractor.extract(uploaded_file: file, raw_bytes: "hello world".b)

      assert_equal "plain", result[:format]
      assert_equal "hello world", result[:text]
    end

    test "extract converts xlsx document to csv text" do
      extractor = ContextTextExtractor.new
      xlsx_bytes = build_minimal_xlsx(
        shared_strings: [ "name", "score", "alice" ],
        sheet_rows: [
          [ { t: "s", v: "0" }, { t: "s", v: "1" } ],
          [ { t: "s", v: "2" }, { t: nil, v: "95" } ]
        ]
      )
      file = build_upload(
        content: xlsx_bytes,
        filename: "scores.xlsx",
        content_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
      )

      result = extractor.extract(uploaded_file: file, raw_bytes: xlsx_bytes)

      assert_equal "csv", result[:format]
      assert_includes result[:text], "name,score"
      assert_includes result[:text], "alice,95"
    end

    test "extract uses ocr client for pdf/image types" do
      ocr_client = FakeOcrClient.new(output: "OCR TEXT")
      extractor = ContextTextExtractor.new(ocr_client: ocr_client)
      pdf_bytes = "%PDF-1.7 test".b
      file = build_upload(
        content: pdf_bytes,
        filename: "scan.pdf",
        content_type: "application/pdf"
      )

      result = extractor.extract(uploaded_file: file, raw_bytes: pdf_bytes)

      assert_equal "ocr", result[:format]
      assert_equal "OCR TEXT", result[:text]
      assert_equal 1, ocr_client.calls.length
      assert_equal "application/pdf", ocr_client.calls.first[:mime_type]
      assert_equal "scan.pdf", ocr_client.calls.first[:filename]
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

    def build_minimal_xlsx(shared_strings:, sheet_rows:)
      sheet_xml = <<~XML
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
          <sheetData>
            #{sheet_rows_xml(sheet_rows)}
          </sheetData>
        </worksheet>
      XML

      shared_strings_xml = <<~XML
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" count="#{shared_strings.length}" uniqueCount="#{shared_strings.length}">
          #{shared_strings.map { |value| "<si><t>#{value}</t></si>" }.join}
        </sst>
      XML

      buffer = Zip::OutputStream.write_buffer do |zip|
        zip.put_next_entry("xl/sharedStrings.xml")
        zip.write(shared_strings_xml)
        zip.put_next_entry("xl/worksheets/sheet1.xml")
        zip.write(sheet_xml)
      end
      buffer.rewind
      buffer.read
    end

    def sheet_rows_xml(rows)
      rows.each_with_index.map do |cells, row_index|
        row_number = row_index + 1
        rendered_cells = cells.each_with_index.map do |cell, col_index|
          cell_ref = "#{column_name(col_index)}#{row_number}"
          type = cell[:t]
          value = cell[:v].to_s

          if type.present?
            "<c r=\"#{cell_ref}\" t=\"#{type}\"><v>#{value}</v></c>"
          else
            "<c r=\"#{cell_ref}\"><v>#{value}</v></c>"
          end
        end.join

        "<row r=\"#{row_number}\">#{rendered_cells}</row>"
      end.join
    end

    def column_name(index)
      (65 + index).chr
    end
  end
end
