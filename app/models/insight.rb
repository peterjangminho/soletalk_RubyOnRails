class Insight < ApplicationRecord
  belongs_to :user

  validates :situation, :decision, :action_guide, :data_info, presence: true
end
