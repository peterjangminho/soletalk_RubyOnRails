require "test_helper"

class DeadLetterCallbackTest < ActiveJob::TestCase
  class FakeNotifier
    cattr_accessor :payload

    def record(job_class:, arguments:, error_class:, error_message:, failed_at:)
      self.class.payload = {
        job_class: job_class,
        arguments: arguments,
        error_class: error_class,
        error_message: error_message,
        failed_at: failed_at
      }
    end
  end

  test "P31-T2 background jobs register after_discard dead-letter callback" do
    original = ExternalInfoJob.dead_letter_notifier_class
    ExternalInfoJob.dead_letter_notifier_class = FakeNotifier
    FakeNotifier.payload = nil

    assert ExternalInfoJob.after_discard_procs.any?

    job = ExternalInfoJob.new
    error = RuntimeError.new("discarded")
    ExternalInfoJob.after_discard_procs.last.call(job, error)

    assert_equal "ExternalInfoJob", FakeNotifier.payload[:job_class]
    assert_equal "RuntimeError", FakeNotifier.payload[:error_class]
    assert_equal "discarded", FakeNotifier.payload[:error_message]
  ensure
    ExternalInfoJob.dead_letter_notifier_class = original if original
  end
end
