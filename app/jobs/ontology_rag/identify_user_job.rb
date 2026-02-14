module OntologyRag
  class IdentifyUserJob < ApplicationJob
    queue_as :default

    class_attribute :user_sync_service_class, default: OntologyRag::UserSyncService

    def perform(google_sub)
      user_sync_service_class.new.call(google_sub: google_sub)
    end
  end
end
