require "test_helper"

class ExternalInfoJobTest < ActiveJob::TestCase
  class FakeClient
    cattr_accessor :received_queries

    self.received_queries = []

    def query(question:, google_sub:, limit:)
      self.class.received_queries << {
        question: question,
        google_sub: google_sub,
        limit: limit
      }
      { answer: "ok", sources: [] }
    end
  end

  test "P30-T1 ExternalInfoJob skips collection for free tier users" do
    user = User.create!(google_sub: "g-external-free", subscription_tier: "free")
    ExternalInfoJob.client_class = FakeClient
    FakeClient.received_queries = []

    result = ExternalInfoJob.perform_now(
      user_id: user.id,
      info_requests: [ { type: "A", query: "market trend" } ]
    )

    assert_equal true, result[:skipped]
    assert_equal "premium_required", result[:reason]
    assert_empty FakeClient.received_queries
  end

  test "P30-T2 ExternalInfoJob queries OntologyRag for premium users with Type A-D requests" do
    user = User.create!(google_sub: "g-external-premium", subscription_tier: "premium")
    ExternalInfoJob.client_class = FakeClient
    FakeClient.received_queries = []

    result = ExternalInfoJob.perform_now(
      user_id: user.id,
      info_requests: [
        { type: "A", query: "weather tomorrow" },
        { type: "B", query: "finance outlook" },
        { type: "X", query: "ignore this" }
      ]
    )

    assert_equal true, result[:success]
    assert_equal 2, FakeClient.received_queries.size
    assert_equal "weather tomorrow", FakeClient.received_queries[0][:question]
    assert_equal "finance outlook", FakeClient.received_queries[1][:question]
    assert_equal "g-external-premium", FakeClient.received_queries[0][:google_sub]
  end

  test "P30-T3 ExternalInfoJob applies retry policy (3 attempts)" do
    assert_equal 3, ExternalInfoJob::RETRY_ATTEMPTS
  end
end
