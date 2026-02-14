module Jobs
  class DeadLetterNotifier
    CACHE_KEY = "jobs:dead_letters".freeze
    MAX_ITEMS = 100

    class_attribute :memory_store, default: []

    def initialize(cache_store: Rails.cache)
      @cache_store = cache_store
    end

    def record(job_class:, arguments:, error_class:, error_message:, failed_at: Time.current)
      payload = {
        job_class: job_class,
        arguments: arguments,
        error_class: error_class,
        error_message: error_message,
        failed_at: failed_at.iso8601
      }

      self.class.memory_store = ([ payload ] + self.class.memory_store).take(MAX_ITEMS)
      @cache_store.write(CACHE_KEY, ([ payload ] + list).take(MAX_ITEMS))
      payload
    end

    def list
      cached = @cache_store.read(CACHE_KEY)
      cached.presence || self.class.memory_store
    end
  end
end
