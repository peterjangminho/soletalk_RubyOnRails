require "test_helper"

class OntologyRagIdentifyUserJobTest < ActiveJob::TestCase
  class FakeUserSyncService
    cattr_accessor :received_google_sub

    def call(google_sub:)
      self.class.received_google_sub = google_sub
      { success: true }
    end
  end

  test "P10-T2 identify user job calls user sync service" do
    original = OntologyRag::IdentifyUserJob.user_sync_service_class
    OntologyRag::IdentifyUserJob.user_sync_service_class = FakeUserSyncService

    OntologyRag::IdentifyUserJob.perform_now("g-job-1")

    assert_equal "g-job-1", FakeUserSyncService.received_google_sub
  ensure
    OntologyRag::IdentifyUserJob.user_sync_service_class = original if original
  end
end
