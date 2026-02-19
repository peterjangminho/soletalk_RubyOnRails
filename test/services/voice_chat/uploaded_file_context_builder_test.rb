require "test_helper"

class VoiceChatUploadedFileContextBuilderTest < ActiveSupport::TestCase
  test "VO-P4-T1 returns empty context when user has no uploaded files" do
    user = User.create!(google_sub: "no-files-user")

    result = VoiceChat::UploadedFileContextBuilder.new(user: user).build

    assert_equal [], result[:files]
    assert_equal "", result[:summary]
  end

  test "VO-P4-T2 returns file metadata when user has uploaded files" do
    user = User.create!(google_sub: "has-files-user")
    user.uploaded_files.attach(
      io: StringIO.new("Meeting notes: discuss Q3 budget"),
      filename: "notes.txt",
      content_type: "text/plain"
    )

    result = VoiceChat::UploadedFileContextBuilder.new(user: user).build

    assert_equal 1, result[:files].length
    file_entry = result[:files].first
    assert_equal "notes.txt", file_entry[:filename]
    assert_equal "text/plain", file_entry[:content_type]
    assert file_entry[:byte_size].positive?
    assert result[:summary].present?
  end

  test "VO-P4-T3 includes text content for plain text files" do
    user = User.create!(google_sub: "text-content-user")
    user.uploaded_files.attach(
      io: StringIO.new("Important decision: change teams"),
      filename: "decision.txt",
      content_type: "text/plain"
    )

    result = VoiceChat::UploadedFileContextBuilder.new(user: user).build

    file_entry = result[:files].first
    assert_includes file_entry[:text_preview], "Important decision"
  end

  test "VO-P4-T4 skips text extraction for non-text files" do
    user = User.create!(google_sub: "pdf-user")
    user.uploaded_files.attach(
      io: StringIO.new("%PDF-1.4 binary content"),
      filename: "report.pdf",
      content_type: "application/pdf"
    )

    result = VoiceChat::UploadedFileContextBuilder.new(user: user).build

    file_entry = result[:files].first
    assert_equal "report.pdf", file_entry[:filename]
    assert_nil file_entry[:text_preview]
  end
end
