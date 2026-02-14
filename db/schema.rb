# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_02_14_194000) do
  create_table "depth_explorations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.json "impacts", default: {}, null: false
    t.json "information_needs", default: {}, null: false
    t.text "q1_answer", null: false
    t.text "q2_answer", null: false
    t.text "q3_answer", null: false
    t.text "q4_answer", null: false
    t.float "signal_emotion_level", default: 0.0, null: false
    t.json "signal_keywords", default: [], null: false
    t.integer "signal_repetition_count", default: 0, null: false
    t.datetime "updated_at", null: false
  end

  create_table "insights", force: :cascade do |t|
    t.text "action_guide", null: false
    t.datetime "created_at", null: false
    t.text "data_info", null: false
    t.text "decision", null: false
    t.json "engc_profile", default: {}, null: false
    t.text "situation", null: false
    t.datetime "updated_at", null: false
  end

  create_table "messages", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.string "message_type", default: "text", null: false
    t.json "metadata", default: {}, null: false
    t.string "role", null: false
    t.integer "session_id", null: false
    t.datetime "updated_at", null: false
    t.index ["role"], name: "index_messages_on_role"
    t.index ["session_id"], name: "index_messages_on_session_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "ended_at"
    t.json "metadata", default: {}, null: false
    t.datetime "started_at"
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["status"], name: "index_sessions_on_status"
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "language", default: "ko", null: false
    t.json "preferences", default: {}, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.float "voice_speed", default: 1.0, null: false
    t.index ["user_id"], name: "index_settings_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "avatar_url"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "google_sub", null: false
    t.string "name"
    t.string "revenue_cat_id"
    t.datetime "subscription_expires_at"
    t.string "subscription_status", default: "free", null: false
    t.string "subscription_tier", default: "free", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email"
    t.index ["google_sub"], name: "index_users_on_google_sub", unique: true
    t.index ["revenue_cat_id"], name: "index_users_on_revenue_cat_id"
    t.index ["subscription_status"], name: "index_users_on_subscription_status"
  end

  create_table "voice_chat_data", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "current_phase", default: "opener", null: false
    t.float "emotion_level", default: 0.0, null: false
    t.float "energy_level", default: 0.0, null: false
    t.json "metadata", default: {}, null: false
    t.json "phase_history", default: [], null: false
    t.integer "session_id", null: false
    t.datetime "updated_at", null: false
    t.index ["current_phase"], name: "index_voice_chat_data_on_current_phase"
    t.index ["session_id"], name: "index_voice_chat_data_on_session_id"
  end

  add_foreign_key "messages", "sessions"
  add_foreign_key "sessions", "users"
  add_foreign_key "settings", "users"
  add_foreign_key "voice_chat_data", "sessions"
end
