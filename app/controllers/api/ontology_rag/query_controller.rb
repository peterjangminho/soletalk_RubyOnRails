module Api
  module OntologyRag
    class QueryController < ApplicationController
      class_attribute :client_class, default: ::OntologyRag::Client

      def create
        question = params[:question].to_s.strip
        if question.blank?
          render json: { success: false, error: "question is required" }, status: :unprocessable_entity
          return
        end

        response = client_class.new.query(
          question: question,
          google_sub: params[:google_sub],
          limit: params[:limit] || 5,
          container_id: params[:container_id]
        )

        if response.is_a?(Hash) && response[:answer].present?
          render json: response.merge(success: true)
        else
          render json: {
            success: false,
            error: (response[:error] || "upstream_error"),
            message: response[:message]
          }, status: :bad_gateway
        end
      end
    end
  end
end
