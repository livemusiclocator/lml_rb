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

ActiveRecord::Schema[8.1].define(version: 2026_08_04_010000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "status", ["draft", "confirmed", "cancelled"]
  create_enum "ticket_status", ["selling_fast", "sold_out"]

  create_table "act_managers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "act_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["act_id"], name: "index_act_managers_on_act_id"
    t.index ["user_id", "act_id"], name: "index_act_managers_on_user_id_and_act_id", unique: true
    t.index ["user_id"], name: "index_act_managers_on_user_id"
  end

  create_table "acts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "bandcamp"
    t.string "country"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "facebook"
    t.jsonb "genres"
    t.string "instagram"
    t.string "linktree"
    t.string "location"
    t.string "musicbrainz"
    t.string "name"
    t.string "rym"
    t.string "spotify"
    t.datetime "updated_at", null: false
    t.string "website"
    t.string "wikipedia"
    t.string "youtube"
  end

  create_table "admin_users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "last_active_at"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "time_zone"
    t.datetime "updated_at", null: false
    t.string "username"
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
  end

  create_table "explorer_configs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "allow_all_locations"
    t.datetime "created_at", null: false
    t.string "default_location"
    t.string "edition_id"
    t.text "selectable_locations"
    t.datetime "updated_at", null: false
  end

  create_table "gigs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "category"
    t.boolean "checked", default: false
    t.datetime "created_at", null: false
    t.date "date"
    t.text "description"
    t.integer "duration"
    t.string "genre_tags", array: true
    t.boolean "hidden", default: false
    t.string "information_tags", array: true
    t.text "internal_description"
    t.string "name"
    t.string "proposed_genre_tags", array: true
    t.string "series"
    t.string "source"
    t.integer "start_offset"
    t.enum "status", default: "confirmed", null: false, enum_type: "status"
    t.enum "ticket_status", enum_type: "ticket_status"
    t.string "ticketing_url"
    t.datetime "updated_at", null: false
    t.uuid "upload_id"
    t.string "url"
    t.uuid "venue_id"
    t.index ["venue_id"], name: "index_gigs_on_venue_id"
  end

  create_table "good_job_batches", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "callback_priority"
    t.text "callback_queue_name"
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "discarded_at"
    t.datetime "enqueued_at"
    t.datetime "finished_at"
    t.datetime "jobs_finished_at"
    t.text "on_discard"
    t.text "on_finish"
    t.text "on_success"
    t.jsonb "serialized_properties"
    t.datetime "updated_at", null: false
  end

  create_table "good_job_executions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "active_job_id", null: false
    t.datetime "created_at", null: false
    t.interval "duration"
    t.text "error"
    t.text "error_backtrace", array: true
    t.integer "error_event", limit: 2
    t.datetime "finished_at"
    t.text "job_class"
    t.uuid "process_id"
    t.text "queue_name"
    t.datetime "scheduled_at"
    t.jsonb "serialized_params"
    t.datetime "updated_at", null: false
    t.index ["active_job_id", "created_at"], name: "index_good_job_executions_on_active_job_id_and_created_at"
    t.index ["process_id", "created_at"], name: "index_good_job_executions_on_process_id_and_created_at"
  end

  create_table "good_job_processes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "lock_type", limit: 2
    t.jsonb "state"
    t.datetime "updated_at", null: false
  end

  create_table "good_job_settings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "key"
    t.datetime "updated_at", null: false
    t.jsonb "value"
    t.index ["key"], name: "index_good_job_settings_on_key", unique: true
  end

  create_table "good_jobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "active_job_id"
    t.uuid "batch_callback_id"
    t.uuid "batch_id"
    t.text "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "cron_at"
    t.text "cron_key"
    t.text "error"
    t.integer "error_event", limit: 2
    t.integer "executions_count"
    t.datetime "finished_at"
    t.boolean "is_discrete"
    t.text "job_class"
    t.text "labels", array: true
    t.integer "lock_type", limit: 2
    t.datetime "locked_at"
    t.uuid "locked_by_id"
    t.datetime "performed_at"
    t.integer "priority"
    t.text "queue_name"
    t.uuid "retried_good_job_id"
    t.datetime "scheduled_at"
    t.jsonb "serialized_params"
    t.datetime "updated_at", null: false
    t.index ["active_job_id", "created_at"], name: "index_good_jobs_on_active_job_id_and_created_at"
    t.index ["batch_callback_id"], name: "index_good_jobs_on_batch_callback_id", where: "(batch_callback_id IS NOT NULL)"
    t.index ["batch_id"], name: "index_good_jobs_on_batch_id", where: "(batch_id IS NOT NULL)"
    t.index ["concurrency_key", "created_at"], name: "index_good_jobs_on_concurrency_key_and_created_at"
    t.index ["concurrency_key"], name: "index_good_jobs_on_concurrency_key_when_unfinished", where: "(finished_at IS NULL)"
    t.index ["created_at"], name: "index_good_jobs_on_created_at"
    t.index ["cron_key", "created_at"], name: "index_good_jobs_on_cron_key_and_created_at_cond", where: "(cron_key IS NOT NULL)"
    t.index ["cron_key", "cron_at"], name: "index_good_jobs_on_cron_key_and_cron_at_cond", unique: true, where: "(cron_key IS NOT NULL)"
    t.index ["finished_at"], name: "index_good_jobs_jobs_on_finished_at_only", where: "(finished_at IS NOT NULL)"
    t.index ["finished_at"], name: "index_good_jobs_on_discarded", order: :desc, where: "((finished_at IS NOT NULL) AND (error IS NOT NULL))"
    t.index ["id"], name: "index_good_jobs_on_unfinished_or_errored", where: "((finished_at IS NULL) OR (error IS NOT NULL))"
    t.index ["job_class"], name: "index_good_jobs_on_job_class"
    t.index ["labels"], name: "index_good_jobs_on_labels", where: "(labels IS NOT NULL)", using: :gin
    t.index ["locked_by_id"], name: "index_good_jobs_on_locked_by_id", where: "(locked_by_id IS NOT NULL)"
    t.index ["priority", "created_at"], name: "index_good_job_jobs_for_candidate_lookup", where: "(finished_at IS NULL)"
    t.index ["priority", "created_at"], name: "index_good_jobs_jobs_on_priority_created_at_when_unfinished", order: { priority: "DESC NULLS LAST" }, where: "(finished_at IS NULL)"
    t.index ["priority", "scheduled_at", "id"], name: "index_good_jobs_for_candidate_dequeue_unlocked", where: "((finished_at IS NULL) AND (locked_by_id IS NULL))"
    t.index ["priority", "scheduled_at", "id"], name: "index_good_jobs_on_priority_scheduled_at_unfinished", where: "(finished_at IS NULL)"
    t.index ["priority", "scheduled_at"], name: "index_good_jobs_on_priority_scheduled_at_unfinished_unlocked", where: "((finished_at IS NULL) AND (locked_by_id IS NULL))"
    t.index ["queue_name", "scheduled_at", "id"], name: "index_good_jobs_on_queue_name_priority_scheduled_at_unfinished", where: "(finished_at IS NULL)"
    t.index ["queue_name", "scheduled_at"], name: "index_good_jobs_on_queue_name_and_scheduled_at", where: "(finished_at IS NULL)"
    t.index ["queue_name"], name: "index_good_jobs_on_queue_name"
    t.index ["scheduled_at", "queue_name"], name: "index_good_jobs_on_scheduled_at_and_queue_name"
    t.index ["scheduled_at"], name: "index_good_jobs_on_scheduled_at", where: "(finished_at IS NULL)"
  end

  create_table "locations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "internal_identifier", null: false
    t.float "latitude", null: false
    t.float "longitude", null: false
    t.integer "map_zoom_level", default: 15, null: false
    t.string "name", null: false
    t.string "seo_title_format_string"
    t.datetime "updated_at", null: false
    t.json "visible_in_editions", default: []
  end

  create_table "prices", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "cents"
    t.datetime "created_at", null: false
    t.string "description"
    t.uuid "gig_id"
    t.datetime "updated_at", null: false
  end

  create_table "proposals", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "note"
    t.jsonb "proposed_attributes", default: {}
    t.string "proposed_type"
    t.datetime "reviewed_at"
    t.uuid "reviewed_by_id"
    t.text "reviewer_note"
    t.integer "status", default: 0, null: false
    t.uuid "target_id"
    t.string "target_type"
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["reviewed_by_id"], name: "index_proposals_on_reviewed_by_id"
    t.index ["status"], name: "index_proposals_on_status"
    t.index ["target_type", "target_id"], name: "index_proposals_on_target_type_and_target_id"
    t.index ["user_id"], name: "index_proposals_on_user_id"
  end

  create_table "series_themes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "default_map_pin"
    t.uuid "explorer_config_id", null: false
    t.string "saved_map_pin"
    t.string "search_result"
    t.string "series_name"
    t.datetime "updated_at", null: false
    t.index ["explorer_config_id"], name: "index_series_themes_on_explorer_config_id"
  end

  create_table "sets", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "act_id"
    t.datetime "created_at", null: false
    t.integer "duration"
    t.uuid "gig_id"
    t.string "stage"
    t.integer "start_offset"
    t.datetime "updated_at", null: false
    t.index ["act_id"], name: "index_sets_on_act_id"
    t.index ["gig_id"], name: "index_sets_on_gig_id"
  end

  create_table "uploads", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.text "error_description"
    t.string "format"
    t.string "source"
    t.string "status"
    t.string "time_zone"
    t.datetime "updated_at", null: false
    t.uuid "venue_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.string "display_name"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "unconfirmed_email"
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "venue_managers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.uuid "venue_id", null: false
    t.index ["user_id", "venue_id"], name: "index_venue_managers_on_user_id_and_venue_id", unique: true
    t.index ["user_id"], name: "index_venue_managers_on_user_id"
    t.index ["venue_id"], name: "index_venue_managers_on_venue_id"
  end

  create_table "venues", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "address"
    t.jsonb "address_components", default: {}, null: false
    t.uuid "admin_user_id"
    t.integer "capacity"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "facebook_url"
    t.string "google_business_status"
    t.string "google_place_id"
    t.string "instagram_url"
    t.float "latitude"
    t.string "location"
    t.string "location_url"
    t.float "longitude"
    t.string "name"
    t.text "notes"
    t.string "phone"
    t.string "postcode"
    t.jsonb "tags"
    t.string "time_zone"
    t.datetime "updated_at", null: false
    t.string "vibe"
    t.string "website"
    t.index ["address_components"], name: "index_venues_on_address_components", using: :gin
    t.index ["admin_user_id"], name: "index_venues_on_admin_user_id"
    t.index ["google_business_status"], name: "index_venues_on_google_business_status"
    t.index ["google_place_id"], name: "index_venues_on_google_place_id"
  end

  add_foreign_key "act_managers", "acts"
  add_foreign_key "act_managers", "users"
  add_foreign_key "gigs", "venues"
  add_foreign_key "proposals", "admin_users", column: "reviewed_by_id"
  add_foreign_key "proposals", "users"
  add_foreign_key "series_themes", "explorer_configs"
  add_foreign_key "sets", "acts"
  add_foreign_key "sets", "gigs"
  add_foreign_key "venue_managers", "users"
  add_foreign_key "venue_managers", "venues"
end
