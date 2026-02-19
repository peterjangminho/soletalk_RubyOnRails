require "test_helper"

class OntologyRagConstantsTest < ActiveSupport::TestCase
  test "P6-T1 defines P0 endpoint paths and timeout policy" do
    assert_equal "/engine/users/identify", OntologyRag::Constants::ENDPOINTS[:identify_user]
    assert_equal "/engine/prompts/%{google_sub}", OntologyRag::Constants::ENDPOINTS[:get_profile]
    assert_equal "/incar/profile/%{google_sub}", OntologyRag::Constants::ENDPOINTS[:get_cached_profile]
    assert_equal "/incar/events/batch", OntologyRag::Constants::ENDPOINTS[:batch_save_events]
    assert_equal "/incar/conversations/%{session_id}/save", OntologyRag::Constants::ENDPOINTS[:save_conversation]
    assert_equal "/engine/objects", OntologyRag::Constants::ENDPOINTS[:create_object]
    assert_equal "/engine/documents", OntologyRag::Constants::ENDPOINTS[:create_document]
    assert_nil OntologyRag::Constants::ENDPOINTS[:upsert_vector]

    assert_operator OntologyRag::Constants::TIMEOUTS[:open], :>, 0
    assert_operator OntologyRag::Constants::TIMEOUTS[:read], :>, 0
    assert_operator OntologyRag::Constants::TIMEOUTS[:retries], :>=, 0
  end
end
