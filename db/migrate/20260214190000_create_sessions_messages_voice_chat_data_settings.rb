class CreateSessionsMessagesVoiceChatDataSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :status, null: false, default: "active"
      t.datetime :started_at
      t.datetime :ended_at
      t.json :metadata, null: false, default: {}

      t.timestamps
    end

    create_table :messages do |t|
      t.references :session, null: false, foreign_key: true
      t.string :role, null: false
      t.text :content, null: false
      t.string :message_type, null: false, default: "text"
      t.json :metadata, null: false, default: {}

      t.timestamps
    end

    create_table :voice_chat_data do |t|
      t.references :session, null: false, foreign_key: true
      t.string :current_phase, null: false, default: "opener"
      t.float :emotion_level, null: false, default: 0.0
      t.float :energy_level, null: false, default: 0.0
      t.json :phase_history, null: false, default: []
      t.json :metadata, null: false, default: {}

      t.timestamps
    end

    create_table :settings do |t|
      t.references :user, null: false, foreign_key: true
      t.string :language, null: false, default: "ko"
      t.float :voice_speed, null: false, default: 1.0
      t.json :preferences, null: false, default: {}

      t.timestamps
    end

    add_index :sessions, :status
    add_index :messages, :role
    add_index :voice_chat_data, :current_phase
  end
end
