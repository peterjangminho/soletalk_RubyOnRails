class Message < ApplicationRecord
  belongs_to :session

  enum :role, {
    user: "user",
    assistant: "assistant",
    system: "system"
  }

  validates :role, :content, presence: true
end
