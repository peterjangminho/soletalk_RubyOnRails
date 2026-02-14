class AddSubscriptionFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :subscription_status, :string, null: false, default: "free"
    add_column :users, :subscription_expires_at, :datetime
    add_column :users, :revenue_cat_id, :string

    add_index :users, :subscription_status
    add_index :users, :revenue_cat_id
  end
end
