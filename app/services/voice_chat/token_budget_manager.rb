module VoiceChat
  class TokenBudgetManager
    LAYER_RATIOS = {
      profile: 0.10,
      past_memory: 0.20,
      current_session: 0.30,
      additional_info: 0.15,
      ai_persona: 0.15
    }.freeze

    def initialize(total_tokens:)
      @total_tokens = total_tokens
    end

    def allocate
      LAYER_RATIOS.each_with_object({}) do |(layer, ratio), budget|
        budget[layer] = (@total_tokens * ratio).to_i
      end
    end
  end
end
