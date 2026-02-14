require "test_helper"

class OntologyRagEngcEventBatchJobTest < ActiveJob::TestCase
  class FakeClient
    cattr_accessor :received_payload

    def record_events(google_sub:, events:)
      self.class.received_payload = {
        google_sub: google_sub,
        events: events
      }
      { "success" => true }
    end
  end

  test "P29-T1 EngcEventBatchJob sends events to OntologyRag::Client#record_events" do
    original = OntologyRag::EngcEventBatchJob.client_class
    OntologyRag::EngcEventBatchJob.client_class = FakeClient

    events = [ { type: "emotion", value: 0.7 } ]
    OntologyRag::EngcEventBatchJob.perform_now("g-events", events)

    assert_equal "g-events", FakeClient.received_payload[:google_sub]
    assert_equal events, FakeClient.received_payload[:events]
  ensure
    OntologyRag::EngcEventBatchJob.client_class = original if original
  end

  test "P29-T3 EngcEventBatchJob applies retry policy of 3 attempts" do
    assert_equal 3, OntologyRag::EngcEventBatchJob::RETRY_ATTEMPTS
  end
end
