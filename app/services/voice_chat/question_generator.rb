module VoiceChat
  class QuestionGenerator
    QUESTIONS = {
      q1: "왜 이 문제가 지금 중요하게 느껴지나요?",
      q2: "여기서 어떤 결정을 가장 고민하고 있나요?",
      q3: "이 결정이 당신과 주변에 어떤 영향을 줄까요?",
      q4: "더 나은 결정을 위해 어떤 정보가 필요할까요?"
    }.freeze

    def question_for(step)
      QUESTIONS.fetch(step)
    end
  end
end
