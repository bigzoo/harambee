# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170930080234) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "transactions", force: :cascade do |t|
    t.integer "user_harambee_id"
    t.string "contributor_amount"
    t.string "contributor_phone_no"
    t.string "transaction_code"
    t.string "transaction_confirmation"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "receipt_no"
    t.string "transaction_date"
    t.boolean "done"
    t.string "merchant_request_id"
    t.string "checkout_request_id"
    t.index ["user_harambee_id"], name: "index_transactions_on_user_harambee_id"
  end

  create_table "user_harambees", force: :cascade do |t|
    t.string "name"
    t.integer "user_id"
    t.string "description"
    t.string "target_amount"
    t.string "raised_amount", default: "0"
    t.string "phone_no"
    t.datetime "deadline"
    t.boolean "running", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "image"
    t.index ["user_id"], name: "index_user_harambees_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "provider"
    t.string "uid"
    t.string "name"
    t.string "email"
    t.string "image"
    t.string "oauth_token"
    t.string "oauth_refresh_token"
    t.datetime "oauth_expires_at"
    t.string "national_id"
    t.string "phone_no"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
