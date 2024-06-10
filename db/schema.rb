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

ActiveRecord::Schema[7.1].define(version: 2024_06_10_014716) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "status", ["draft", "confirmed", "cancelled"]

  create_table "acts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "country"
    t.string "location"
    t.jsonb "genres"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "admin_users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "time_zone"
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
  end

  create_table "gigs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.date "date"
    t.datetime "start_time", precision: nil
    t.datetime "finish_time", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "venue_id"
    t.enum "status", default: "draft", null: false, enum_type: "status"
    t.string "ticketing_url"
    t.jsonb "tags"
    t.text "description"
    t.integer "start_offset"
    t.integer "duration"
    t.boolean "hidden"
    t.boolean "checked"
    t.string "source"
    t.uuid "upload_id"
    t.index ["venue_id"], name: "index_gigs_on_venue_id"
  end

  create_table "prices", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "gig_id"
    t.integer "cents"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sets", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "start_time", precision: nil
    t.datetime "finish_time", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "gig_id"
    t.uuid "act_id"
    t.integer "start_offset"
    t.integer "duration"
    t.string "stage"
    t.index ["act_id"], name: "index_sets_on_act_id"
    t.index ["gig_id"], name: "index_sets_on_gig_id"
  end

  create_table "uploads", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "format"
    t.text "content"
    t.string "source"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "time_zone"
    t.uuid "venue_id"
    t.jsonb "gig_ids"
    t.string "status"
    t.text "error_description"
  end

  create_table "venues", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "address"
    t.string "location_url"
    t.float "latitude"
    t.float "longitude"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "location"
    t.string "time_zone"
    t.string "website"
    t.integer "capacity"
    t.string "postcode"
    t.string "vibe"
    t.jsonb "tags"
  end

  add_foreign_key "gigs", "venues"
  add_foreign_key "sets", "acts"
  add_foreign_key "sets", "gigs"
end
