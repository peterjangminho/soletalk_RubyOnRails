require "test_helper"

class AuthGoogleSubExtractorTest < ActiveSupport::TestCase
  test "P7-T2 extracts google_sub from omniauth auth hash" do
    auth_hash = {
      "uid" => "google-sub-123",
      "info" => { "email" => "x@example.com" }
    }

    google_sub = Auth::GoogleSubExtractor.call(auth_hash)

    assert_equal "google-sub-123", google_sub
  end
end
