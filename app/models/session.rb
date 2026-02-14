class Session < ApplicationRecord
  belongs_to :user
  has_many :messages, dependent: :destroy
  has_one :voice_chat_data, dependent: :destroy

  enum :status, {
    active: "active",
    paused: "paused",
    completed: "completed"
  }

  validates :status, presence: true
end
