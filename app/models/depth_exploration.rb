class DepthExploration < ApplicationRecord
  validates :signal_emotion_level, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }
  validates :q1_answer, :q2_answer, :q3_answer, :q4_answer, presence: true
end
