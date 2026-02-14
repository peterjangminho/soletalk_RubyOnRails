class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :google_sub, null: false
      t.string :email
      t.string :name
      t.string :avatar_url
      t.string :subscription_tier, null: false, default: "free"

      t.timestamps
    end

    add_index :users, :google_sub, unique: true
    add_index :users, :email
  end
end
