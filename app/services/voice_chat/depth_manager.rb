module VoiceChat
  class DepthManager
    STEPS = %i[q1 q2 q3 q4].freeze

    def initialize
      @answers = {}
    end

    def record_answer(step, answer)
      @answers[step] = answer
    end

    def progress
      (@answers.keys.count.to_f / STEPS.count).round(2)
    end

    def completed?
      STEPS.all? { |step| @answers[step].present? }
    end
  end
end
