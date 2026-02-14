class Insight < ApplicationRecord
  validates :situation, :decision, :action_guide, :data_info, presence: true
end
