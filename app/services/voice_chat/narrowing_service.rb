module VoiceChat
  class NarrowingService
    def next_question(stage:, topic:)
      case stage
      when 1
        "#{topic}에 대해 지금 가장 크게 느끼는 건 무엇인가요?"
      when 2
        "그중에서도 구체적으로 어떤 상황이 가장 부담되나요?"
      else
        "그 상황에서 지금 당장 바꿀 수 있는 한 가지는 무엇인가요?"
      end
    end
  end
end
