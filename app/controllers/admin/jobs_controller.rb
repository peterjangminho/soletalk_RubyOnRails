module Admin
  class JobsController < ApplicationController
    before_action :authenticate_user!

    def show
      @failed_executions_count = fetch_failed_executions_count
      @dead_letters = Jobs::DeadLetterNotifier.new.list
    end

    private

    def fetch_failed_executions_count
      return 0 unless defined?(SolidQueue::FailedExecution)

      SolidQueue::FailedExecution.count
    rescue ActiveRecord::StatementInvalid
      0
    end
  end
end
