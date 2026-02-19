require "nokogiri"
require "stringio"
require "zip"

module Voice
  class ContextTextExtractor
    EXCEL_CONTENT_TYPES = [
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    ].freeze

    OCR_CONTENT_TYPES = %w[application/pdf image/png image/jpeg image/jpg image/webp image/heic image/heif].freeze

    def initialize(ocr_client: nil)
      @ocr_client = ocr_client
    end

    def extract(uploaded_file:, raw_bytes:)
      if excel_file?(uploaded_file)
        {
          text: xlsx_to_csv_text(raw_bytes),
          format: "csv"
        }
      elsif ocr_file?(uploaded_file)
        {
          text: normalize_text(extract_ocr_text(uploaded_file: uploaded_file, raw_bytes: raw_bytes)),
          format: "ocr"
        }
      else
        {
          text: normalize_text(raw_bytes),
          format: "plain"
        }
      end
    end

    private

    def excel_file?(uploaded_file)
      content_type = uploaded_file.content_type.to_s
      return true if EXCEL_CONTENT_TYPES.include?(content_type)

      File.extname(uploaded_file.original_filename.to_s).casecmp(".xlsx").zero?
    end

    def ocr_file?(uploaded_file)
      content_type = uploaded_file.content_type.to_s
      return true if OCR_CONTENT_TYPES.include?(content_type)

      extension = File.extname(uploaded_file.original_filename.to_s).downcase
      %w[.pdf .png .jpg .jpeg .webp .heic .heif].include?(extension)
    end

    def normalize_text(raw_bytes)
      raw_bytes.to_s.encode("UTF-8", invalid: :replace, undef: :replace, replace: "").strip
    end

    def xlsx_to_csv_text(raw_bytes)
      rows = []

      Zip::File.open_buffer(StringIO.new(raw_bytes)) do |zip_file|
        shared_strings = extract_shared_strings(zip_file)
        worksheet_entries = zip_file.glob("xl/worksheets/sheet*.xml").sort_by { |entry| sheet_index(entry.name) }

        worksheet_entries.each do |worksheet|
          sheet_doc = Nokogiri::XML(worksheet.get_input_stream.read)
          sheet_doc.xpath("//xmlns:sheetData/xmlns:row").each do |row_node|
            row_values = build_row_values(row_node, shared_strings)
            next if row_values.empty?

            rows << to_csv_line(row_values)
          end
        end
      end

      rows.join("\n").strip
    rescue Zip::Error, Nokogiri::XML::SyntaxError => e
      raise Voice::ContextFileIngestService::IngestError, "Failed to parse spreadsheet: #{e.message}"
    end

    def extract_shared_strings(zip_file)
      entry = zip_file.find_entry("xl/sharedStrings.xml")
      return [] unless entry

      doc = Nokogiri::XML(entry.get_input_stream.read)
      doc.xpath("//xmlns:si").map do |si|
        si.xpath(".//xmlns:t").map(&:text).join
      end
    end

    def sheet_index(path)
      match = path.match(/sheet(\d+)\.xml/)
      return Float::INFINITY unless match

      match[1].to_i
    end

    def build_row_values(row_node, shared_strings)
      values_by_index = {}
      highest_index = -1

      row_node.xpath("xmlns:c").each do |cell|
        index = column_index(cell["r"].to_s)
        next if index.nil?

        values_by_index[index] = extract_cell_text(cell, shared_strings)
        highest_index = [ highest_index, index ].max
      end

      return [] if highest_index.negative?

      Array.new(highest_index + 1) { |i| values_by_index[i].to_s }
    end

    def column_index(cell_ref)
      letters = cell_ref[/\A[A-Z]+/]
      return nil if letters.blank?

      letters.chars.reduce(0) { |acc, char| (acc * 26) + (char.ord - 64) } - 1
    end

    def extract_cell_text(cell, shared_strings)
      type = cell["t"].to_s

      case type
      when "s"
        index = cell.at_xpath("xmlns:v")&.text.to_i
        shared_strings[index].to_s
      when "inlineStr"
        cell.at_xpath("xmlns:is/xmlns:t")&.text.to_s
      else
        cell.at_xpath("xmlns:v")&.text.to_s
      end
    end

    def to_csv_line(values)
      values.map do |value|
        escaped = value.to_s.gsub("\"", "\"\"")
        if escaped.include?(",") || escaped.include?("\"") || escaped.include?("\n")
          "\"#{escaped}\""
        else
          escaped
        end
      end.join(",")
    end

    def extract_ocr_text(uploaded_file:, raw_bytes:)
      ocr_client.extract_text(
        raw_bytes: raw_bytes,
        mime_type: uploaded_file.content_type.to_s,
        filename: uploaded_file.original_filename.to_s
      )
    end

    def ocr_client
      @ocr_client ||= GeminiVisionOcrClient.new
    end
  end
end
