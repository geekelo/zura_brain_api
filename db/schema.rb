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

ActiveRecord::Schema[7.2].define(version: 2026_10_08_170558) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "admin_notes", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.text "body"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_admin_notes_on_client_id"
  end

  create_table "bookings", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.datetime "booking_date"
    t.decimal "amount"
    t.string "cycle"
    t.string "cycle_session"
    t.string "status"
    t.text "comments"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_bookings_on_client_id"
  end

  create_table "clients", force: :cascade do |t|
    t.string "name"
    t.string "phone"
    t.text "other_phones"
    t.string "sex"
    t.boolean "adult"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.bigint "session_therapist_id", null: false
    t.decimal "amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_therapist_id"], name: "index_extra_accounts_on_session_therapist_id"
  end

  create_table "extra_expenses", force: :cascade do |t|
    t.text "description"
    t.decimal "amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "lunez_accounts", force: :cascade do |t|
    t.integer "month"
    t.integer "year"
    t.decimal "total_inflow"
    t.decimal "balance"
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

  create_table "main_expenses", force: :cascade do |t|
    t.integer "month"
    t.integer "year"
    t.text "description"
    t.decimal "amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.string "cycle"
    t.string "cycle_session"
    t.boolean "lunez", default: false
    t.decimal "lunez_amount", default: "0.0"
    t.string "hands"
    t.text "comments"
    t.string "status", default: "pending"
    t.boolean "car_washed", default: false
    t.string "proof_of_payment"
    t.bigint "session_creator_id"
    t.string "session_code"
    t.string "session_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_sessions_on_client_id"
    t.index ["session_creator_id"], name: "index_sessions_on_session_creator_id"
  end

  create_table "tech_account_summaries", force: :cascade do |t|
    t.integer "month"
    t.integer "year"
    t.decimal "total_tech_account_inflow"
    t.decimal "total_tech_payin_inflow"
    t.decimal "total_tech_payout_outflow"
    t.decimal "balance"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tech_accounts", force: :cascade do |t|
    t.bigint "extra_account_id", null: false
    t.decimal "amount"
    t.datetime "transaction_date"
    t.boolean "settled"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["extra_account_id"], name: "index_tech_accounts_on_extra_account_id"
  end

  create_table "tech_payins", force: :cascade do |t|
    t.text "description"
    t.decimal "amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tech_payouts", force: :cascade do |t|
    t.text "description"
    t.decimal "amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "therapist_accounts", force: :cascade do |t|
    t.bigint "therapist_id", null: false
    t.integer "month"
    t.integer "year"
    t.decimal "total_therapist_payin"
    t.decimal "total_tip_inflow"
    t.decimal "total_therapist_payout"
    t.decimal "balance"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["therapist_id"], name: "index_therapist_accounts_on_therapist_id"
  end

  create_table "therapist_payins", force: :cascade do |t|
    t.bigint "therapist_id", null: false
    t.text "description"
    t.decimal "amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["therapist_id"], name: "index_therapist_payins_on_therapist_id"
  end

  create_table "therapist_payouts", force: :cascade do |t|
    t.bigint "therapist_id", null: false
    t.text "description"
    t.decimal "amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["therapist_id"], name: "index_therapist_payouts_on_therapist_id"
  end

  create_table "therapists", force: :cascade do |t|
    t.string "work_name"
    t.boolean "active"
    t.string "avatar"
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "admin_notes", "clients"
  add_foreign_key "bookings", "clients"
  add_foreign_key "extra_accounts", "session_therapists"
  add_foreign_key "session_therapists", "sessions"
  add_foreign_key "session_therapists", "therapists"
  add_foreign_key "sessions", "clients"
  add_foreign_key "sessions", "therapists", column: "session_creator_id"
  add_foreign_key "tech_accounts", "extra_accounts"
  add_foreign_key "therapist_accounts", "therapists"
  add_foreign_key "therapist_payins", "therapists"
  add_foreign_key "therapist_payouts", "therapists"
end
