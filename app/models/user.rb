class User < ApplicationRecord
  SUBSCRIPTION_STATUSES = %w[free premium expired].freeze

  has_many :sessions, dependent: :destroy
  has_many :settings, dependent: :destroy

  validates :google_sub, presence: true, uniqueness: true
  validates :subscription_status, inclusion: { in: SUBSCRIPTION_STATUSES }

  def premium?
    subscription_status == "premium" &&
      (subscription_expires_at.nil? || subscription_expires_at > Time.current)
  end
end
