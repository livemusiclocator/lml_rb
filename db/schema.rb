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

ActiveRecord::Schema[8.0].define(version: 2025_08_18_013551) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "status", ["draft", "confirmed", "cancelled"]
  create_enum "ticket_status", ["selling_fast", "sold_out"]

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

  create_table "explorer_configs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "edition_id"
    t.boolean "allow_all_locations"
    t.text "selectable_locations"
    t.string "default_location"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "gigs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.date "date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "venue_id"
    t.enum "status", default: "confirmed", null: false, enum_type: "status"
    t.string "ticketing_url"
    t.text "description"
    t.integer "start_offset"
    t.integer "duration"
    t.boolean "hidden", default: false
    t.boolean "checked", default: false
    t.string "source"
    t.uuid "upload_id"
    t.string "series"
    t.string "category"
    t.string "information_tags", array: true
    t.string "genre_tags", array: true
    t.string "proposed_genre_tags", array: true
    t.text "internal_description"
    t.string "url"
    t.enum "ticket_status", enum_type: "ticket_status"
    t.index ["venue_id"], name: "index_gigs_on_venue_id"
  end

  create_table "locations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "internal_identifier", null: false
    t.string "name", null: false
    t.float "latitude", null: false
    t.float "longitude", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "seo_title_format_string"
    t.integer "map_zoom_level", default: 15, null: false
    t.json "visible_in_editions", default: []
  end

  create_table "prices", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "gig_id"
    t.integer "cents"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "series_themes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "explorer_config_id", null: false
    t.string "series_name"
    t.string "search_result"
    t.string "saved_map_pin"
    t.string "default_map_pin"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["explorer_config_id"], name: "index_series_themes_on_explorer_config_id"
  end

  create_table "sets", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
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
    t.string "email"
    t.string "phone"
    t.text "notes"
    t.string "facebook_url"
    t.string "instagram_url"
  end

  add_foreign_key "gigs", "venues"
  add_foreign_key "series_themes", "explorer_configs"
  add_foreign_key "sets", "acts"
  add_foreign_key "sets", "gigs"
end
