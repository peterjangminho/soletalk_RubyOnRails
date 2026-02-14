module OntologyRag
  class EngcEventBatchJob < ApplicationJob
    queue_as :default

    RETRY_ATTEMPTS = 3

    class_attribute :client_class, default: OntologyRag::Client
    class_attribute :dead_letter_notifier_class, default: Jobs::DeadLetterNotifier

    retry_on StandardError, attempts: RETRY_ATTEMPTS, wait: :polynomially_longer
    after_discard do |job, exception|
      dead_letter_notifier_class.new.record(
        job_class: job.class.name,
        arguments: job.arguments,
        error_class: exception.class.name,
        error_message: exception.message,
        failed_at: Time.current
      )
    end

    def perform(google_sub, events)
      client_class.new.record_events(google_sub: google_sub, events: events)
    end
  end
end
