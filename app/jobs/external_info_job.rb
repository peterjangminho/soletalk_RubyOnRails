class ExternalInfoJob < ApplicationJob
  queue_as :default

  RETRY_ATTEMPTS = 3
  ALLOWED_TYPES = %w[A B C D].freeze

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

  def perform(user_id:, info_requests:)
    user = User.find(user_id)
    return premium_required_result unless premium_user?(user)

    requests = normalize_requests(info_requests)
    client = client_class.new
    collected = requests.map { |request| collect_with_client(client, user, request) }

    { success: true, collected: collected }
  end

  private

  def premium_user?(user)
    user.subscription_tier == "premium"
  end

  def premium_required_result
    {
      success: false,
      skipped: true,
      reason: "premium_required"
    }
  end

  def normalize_requests(info_requests)
    Array(info_requests).filter_map do |item|
      type = item[:type].to_s.upcase
      query = item[:query].to_s.strip
      next if query.blank? || !ALLOWED_TYPES.include?(type)

      { type: type, query: query }
    end
  end

  def collect_with_client(client, user, request)
    response = client.query(question: request[:query], google_sub: user.google_sub, limit: 3)
    request.merge(response: response)
  end
end
