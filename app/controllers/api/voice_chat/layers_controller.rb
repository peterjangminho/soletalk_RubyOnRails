module Api
  module VoiceChat
    class LayersController < ApplicationController
      skip_forgery_protection

      class_attribute :phase_engine_class, default: ::VoiceChat::PhaseTransitionEngine
      class_attribute :depth_service_class, default: ::VoiceChat::DepthExplorationService
      class_attribute :insight_generator_class, default: ::Insight::Generator

      def surface
        session_record = Session.find(params.require(:session_id))
        voice_chat_data = session_record.voice_chat_data || VoiceChatData.create!(session: session_record)
        next_phase = phase_engine_class.new.next_phase(
          current_phase: voice_chat_data.current_phase,
          emotion_level: params.require(:emotion_level).to_f,
          turn_count: params.require(:turn_count).to_i
        )
        voice_chat_data.update!(current_phase: next_phase)

        render json: { success: true, next_phase: next_phase }
      end

      def depth
        depth = depth_service_class.new.record(
          signal_emotion_level: params.require(:signal_emotion_level).to_f,
          signal_keywords: Array(params[:signal_keywords]),
          q1_answer: params.require(:q1_answer),
          q2_answer: params.require(:q2_answer),
          q3_answer: params.require(:q3_answer),
          q4_answer: params.require(:q4_answer),
          impacts: params[:impacts] || {},
          information_needs: params[:information_needs] || {}
        )

        render json: { success: true, depth_exploration_id: depth.id }
      end

      def insight
        session_record = Session.find(params.require(:session_id))

        insight = insight_generator_class.new.call(
          user: session_record.user,
          q1_answer: params.require(:q1_answer),
          q2_answer: params.require(:q2_answer),
          q3_answer: params.require(:q3_answer),
          q4_answer: params.require(:q4_answer)
        )

        render json: { success: true, insight_id: insight.id }
      end
    end
  end
end
