module OntologyRag
  class ConversationSaveJob < ApplicationJob
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

    def perform(session_id)
      session_record = Session.find(session_id)
      client_class.new.save_conversation(
        session_id: session_record.id.to_s,
        google_sub: session_record.user.google_sub,
        conversation: serialized_messages(session_record),
        metadata: { source: "session_end" }
      )
    end

    private

    def serialized_messages(session_record)
      session_record.messages.order(:created_at).map do |message|
        {
          role: message.role,
          content: message.content,
          created_at: message.created_at.iso8601
        }
      end
    end
  end
end
