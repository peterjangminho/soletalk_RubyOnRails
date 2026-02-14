class CreateInsights < ActiveRecord::Migration[8.1]
  def change
    create_table :insights do |t|
      t.text :situation, null: false
      t.text :decision, null: false
      t.text :action_guide, null: false
      t.text :data_info, null: false
      t.json :engc_profile, null: false, default: {}

      t.timestamps
    end
  end
end
