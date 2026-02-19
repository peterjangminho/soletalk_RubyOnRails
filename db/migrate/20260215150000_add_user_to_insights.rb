class AddUserToInsights < ActiveRecord::Migration[8.1]
  def change
    add_reference :insights, :user, foreign_key: true
  end
end
