require "test_helper"

module Jobs
  class DeadLetterNotifierTest < ActiveSupport::TestCase
    setup do
      Rails.cache.delete(Jobs::DeadLetterNotifier::CACHE_KEY)
      Jobs::DeadLetterNotifier.memory_store = []
    end

    test "P31-T1 records discarded job payloads" do
      payload = Jobs::DeadLetterNotifier.new.record(
        job_class: "ExternalInfoJob",
        arguments: [ { user_id: 1 } ],
        error_class: "RuntimeError",
        error_message: "boom"
      )

      list = Jobs::DeadLetterNotifier.new.list

      assert_equal 1, list.size
      assert_equal "ExternalInfoJob", list.first[:job_class]
      assert_equal "RuntimeError", list.first[:error_class]
      assert_equal payload[:error_message], list.first[:error_message]
    end
  end
end
