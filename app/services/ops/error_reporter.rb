module Ops
  class ErrorReporter
    def report(exception:, context: {})
      Rails.logger.error(
        {
          event: "api_exception",
          exception_class: exception.class.name,
          message: exception.message,
          context: context
        }.to_json
      )
    end
  end
end
