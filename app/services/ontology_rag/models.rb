module OntologyRag
  module Models
    class EngcProfile
      KEYS = %i[emotion need goal constraint].freeze

      def initialize(**attributes)
        @attributes = attributes
      end

      def to_h
        KEYS.each_with_object({}) do |key, hash|
          hash[key] = @attributes[key] if @attributes.key?(key)
        end
      end
    end

    class QueryResponse
      attr_reader :answer, :context, :sources, :query

      def initialize(answer:, context:, sources:, query:)
        @answer = answer
        @context = context
        @sources = sources || []
        @query = query
      end

      def self.from_api(payload)
        new(
          answer: payload["answer"],
          context: payload["context"],
          sources: payload["sources"],
          query: payload["query"]
        )
      end
    end
  end
end
