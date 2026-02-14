class CreateDepthExplorations < ActiveRecord::Migration[8.1]
  def change
    create_table :depth_explorations do |t|
      t.float :signal_emotion_level, null: false, default: 0.0
      t.json :signal_keywords, null: false, default: []
      t.integer :signal_repetition_count, null: false, default: 0

      t.text :q1_answer, null: false
      t.text :q2_answer, null: false
      t.text :q3_answer, null: false
      t.text :q4_answer, null: false

      t.json :impacts, null: false, default: {}
      t.json :information_needs, null: false, default: {}

      t.timestamps
    end
  end
end
