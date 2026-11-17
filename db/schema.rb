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

ActiveRecord::Schema[7.2].define(version: 2026_11_17_134600) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "admin_notes", force: :cascade do |t|
    t.bigint "client_id"
    t.bigint "session_id"
    t.bigint "therapist_id"
    t.bigint "creator_id"
    t.text "body"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_admin_notes_on_client_id"
    t.index ["creator_id"], name: "index_admin_notes_on_creator_id"
    t.index ["session_id"], name: "index_admin_notes_on_session_id"
    t.index ["therapist_id"], name: "index_admin_notes_on_therapist_id"
  end

  create_table "client_support_summaries", force: :cascade do |t|
    t.integer "month"
    t.integer "year"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "total_amount", precision: 10, scale: 2
    t.decimal "amount_settled", precision: 10, scale: 2
    t.decimal "amount_unsettled", precision: 10, scale: 2
  end

  create_table "client_supports", force: :cascade do |t|
    t.bigint "session_id", null: false
    t.text "description"
    t.decimal "amount", precision: 10, scale: 2
    t.boolean "settled", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "type"
    t.text "notes"
    t.index ["session_id"], name: "index_client_supports_on_session_id"
  end

  create_table "clients", force: :cascade do |t|
    t.string "name"
    t.string "phone"
    t.text "other_phones", default: [], array: true
    t.string "sex"
    t.integer "cycle"
    t.string "cycle_length"
    t.string "created_by"
    t.boolean "adult"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "client_preferences"
    t.index ["phone"], name: "index_clients_on_phone", unique: true
  end

  create_table "extra_account_summaries", force: :cascade do |t|
    t.integer "month"
    t.integer "year"
    t.decimal "total_extra_account_inflow"
    t.decimal "total_extra_account_outflow"
    t.decimal "balance"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "extra_accounts", force: :cascade do |t|
    t.bigint "session_therapist_id"
    t.string "type"
    t.decimal "amount", precision: 10, scale: 2
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_therapist_id"], name: "index_extra_accounts_on_session_therapist_id"
  end

  create_table "lunez_accounts", force: :cascade do |t|
    t.integer "month"
    t.integer "year"
    t.decimal "total_inflow"
    t.decimal "balance"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "main_account_expenses", force: :cascade do |t|
    t.text "description"
    t.decimal "amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "main_accounts", force: :cascade do |t|
    t.integer "month"
    t.integer "year"
    t.decimal "total_session_inflow"
    t.decimal "total_lunez_inflow"
    t.decimal "total_main_account_outflow"
    t.decimal "balance"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "payment_methods", force: :cascade do |t|
    t.bigint "session_id", null: false
    t.string "source"
    t.string "type"
    t.decimal "amount"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "payment_url", default: [], null: false
    t.datetime "receipt_uploaded_at"
    t.datetime "deleted_at"
    t.index ["session_id"], name: "index_payment_methods_on_session_id"
  end

  create_table "sanctions", force: :cascade do |t|
    t.text "description"
    t.bigint "therapist_id"
    t.string "non_therapist"
    t.decimal "amount", precision: 10, scale: 2
    t.string "type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["therapist_id"], name: "index_sanctions_on_therapist_id"
  end

  create_table "sanctions_summaries", force: :cascade do |t|
    t.integer "month"
    t.integer "year"
    t.decimal "total_payin", precision: 10, scale: 2
    t.decimal "total_payout", precision: 10, scale: 2
    t.decimal "total_balance", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "session_activities", force: :cascade do |t|
    t.bigint "session_id", null: false
    t.bigint "therapist_id", null: false
    t.string "action", null: false
    t.datetime "performed_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_session_activities_on_session_id"
    t.index ["therapist_id"], name: "index_session_activities_on_therapist_id"
  end

  create_table "session_therapists", force: :cascade do |t|
    t.bigint "session_id", null: false
    t.bigint "therapist_id", null: false
    t.string "role"
    t.decimal "tip_amount"
    t.decimal "tip_balance"
    t.decimal "points", default: "0.0"
    t.text "feedback"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_session_therapists_on_session_id"
    t.index ["therapist_id"], name: "index_session_therapists_on_therapist_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.datetime "session_date"
    t.decimal "amount", default: "0.0"
    t.boolean "settled", default: false
    t.integer "cycle"
    t.string "cycle_length"
    t.boolean "lunez", default: false
    t.decimal "lunez_amount", default: "0.0"
    t.string "hands"
    t.jsonb "comments", default: [], null: false
    t.string "status", default: "pending"
    t.bigint "session_creator_id"
    t.string "transaction_id"
    t.string "session_code"
    t.string "session_type", default: "solo, couple, group"
    t.time "start_time"
    t.time "end_time"
    t.integer "duration", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "massage_type"
    t.jsonb "session_history", default: {"ended"=>false, "pending"=>true, "started"=>false, "completed"=>false, "payment_verified"=>false}, null: false
    t.boolean "off_cycle", default: false, null: false
    t.index ["client_id"], name: "index_sessions_on_client_id"
    t.index ["session_code"], name: "index_sessions_on_session_code", unique: true
    t.index ["session_creator_id"], name: "index_sessions_on_session_creator_id"
  end

  create_table "stakes_account_summaries", force: :cascade do |t|
    t.integer "month"
    t.integer "year"
    t.decimal "total_amount", precision: 10, scale: 2
    t.decimal "amount_settled", precision: 10, scale: 2
    t.decimal "amount_unsettled", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "stakes_accounts", force: :cascade do |t|
    t.bigint "session_id", null: false
    t.decimal "amount", precision: 10, scale: 2
    t.boolean "settled", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_stakes_accounts_on_session_id"
  end

  create_table "tech_account_summaries", force: :cascade do |t|
    t.integer "month"
    t.integer "year"
    t.decimal "total_tech_payin"
    t.decimal "total_tech_payout"
    t.decimal "balance"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tech_payins_payouts", force: :cascade do |t|
    t.bigint "extra_account_id"
    t.text "description"
    t.decimal "amount", precision: 10, scale: 2
    t.string "type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["extra_account_id"], name: "index_tech_payins_payouts_on_extra_account_id"
  end

  create_table "therapist_accounts", force: :cascade do |t|
    t.bigint "therapist_id", null: false
    t.integer "month"
    t.integer "year"
    t.decimal "total_therapist_payin"
    t.decimal "total_therapist_payout"
    t.decimal "total_tip_balance"
    t.decimal "balance"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["therapist_id"], name: "index_therapist_accounts_on_therapist_id"
  end

  create_table "therapist_payins_payouts", force: :cascade do |t|
    t.bigint "therapist_id", null: false
    t.text "description"
    t.decimal "amount", precision: 10, scale: 2
    t.string "type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["therapist_id"], name: "index_therapist_payins_payouts_on_therapist_id"
  end

  create_table "therapists", force: :cascade do |t|
    t.string "work_name"
    t.boolean "active", default: true
    t.string "avatar"
    t.string "url"
    t.string "code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_therapists_on_code", unique: true
    t.index ["work_name"], name: "index_therapists_on_work_name", unique: true
  end

  add_foreign_key "admin_notes", "clients"
  add_foreign_key "admin_notes", "sessions"
  add_foreign_key "admin_notes", "therapists"
  add_foreign_key "admin_notes", "therapists", column: "creator_id"
  add_foreign_key "client_supports", "sessions"
  add_foreign_key "extra_accounts", "session_therapists"
  add_foreign_key "payment_methods", "sessions"
  add_foreign_key "sanctions", "therapists", on_delete: :nullify
  add_foreign_key "session_activities", "sessions"
  add_foreign_key "session_activities", "therapists"
  add_foreign_key "session_therapists", "sessions"
  add_foreign_key "session_therapists", "therapists"
  add_foreign_key "sessions", "clients"
  add_foreign_key "sessions", "therapists", column: "session_creator_id"
  add_foreign_key "stakes_accounts", "sessions"
  add_foreign_key "tech_payins_payouts", "extra_accounts"
  add_foreign_key "therapist_accounts", "therapists"
  add_foreign_key "therapist_payins_payouts", "therapists"
end
