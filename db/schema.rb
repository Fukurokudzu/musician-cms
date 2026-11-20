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

ActiveRecord::Schema[8.1].define(version: 2026_11_16_121000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "artists", force: :cascade do |t|
    t.string "title"
    t.string "first_name"
    t.string "last_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "role", default: 0
    t.text "description"
    t.integer "plays_count", default: 0, null: false
    t.boolean "soft_deleted", default: false, null: false
    t.string "path"
    t.string "external_id"
    t.index ["external_id"], name: "index_artists_on_external_id", unique: true
    t.index ["title"], name: "index_artists_on_title", unique: true
  end

  create_table "audit_events", force: :cascade do |t|
    t.string "action", null: false
    t.string "actor"
    t.string "target_type"
    t.string "target_id"
    t.string "target_label"
    t.jsonb "metadata", default: {}, null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.index ["action"], name: "index_audit_events_on_action"
    t.index ["created_at"], name: "index_audit_events_on_created_at"
  end

  create_table "posts", force: :cascade do |t|
    t.string "title", null: false
    t.text "body"
    t.boolean "soft_deleted", default: false, null: false
    t.string "external_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_posts_on_external_id", unique: true
    t.index ["soft_deleted"], name: "index_posts_on_soft_deleted"
  end

  create_table "releases", force: :cascade do |t|
    t.string "title"
    t.string "genre"
    t.string "type"
    t.string "publisher"
    t.bigint "artist_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "release_date"
    t.text "description"
    t.integer "plays_count", default: 0, null: false
    t.string "status", default: "draft"
    t.string "path"
    t.string "external_id"
    t.boolean "allow_zip_download", default: false, null: false
    t.integer "downloads_count", default: 0, null: false
    t.index ["artist_id", "title"], name: "index_releases_on_artist_id_and_title", unique: true
    t.index ["artist_id"], name: "index_releases_on_artist_id"
    t.index ["external_id"], name: "index_releases_on_external_id", unique: true
    t.index ["title"], name: "index_releases_on_title"
  end

  create_table "settings", force: :cascade do |t|
    t.string "var", null: false
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["var"], name: "index_settings_on_var", unique: true
  end

  create_table "stat_events", force: :cascade do |t|
    t.string "kind", null: false
    t.bigint "track_id"
    t.bigint "release_id"
    t.bigint "artist_id"
    t.string "track_title"
    t.string "release_title"
    t.string "artist_title"
    t.string "country_code"
    t.string "country_name"
    t.string "ip_hash"
    t.datetime "created_at", null: false
    t.index ["artist_id"], name: "index_stat_events_on_artist_id"
    t.index ["country_code"], name: "index_stat_events_on_country_code"
    t.index ["created_at"], name: "index_stat_events_on_created_at"
    t.index ["kind", "created_at"], name: "index_stat_events_on_kind_and_created_at"
    t.index ["kind"], name: "index_stat_events_on_kind"
    t.index ["release_id"], name: "index_stat_events_on_release_id"
    t.index ["track_id"], name: "index_stat_events_on_track_id"
  end

  create_table "stats_exports", force: :cascade do |t|
    t.string "status", default: "pending", null: false
    t.string "kind", null: false
    t.string "range", default: "30", null: false
    t.integer "progress", default: 0, null: false
    t.integer "row_count", default: 0, null: false
    t.text "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_stats_exports_on_created_at"
  end

  create_table "tracks", force: :cascade do |t|
    t.string "title"
    t.bigint "release_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "pos"
    t.integer "plays_count", default: 0, null: false
    t.bigint "duration"
    t.string "status", default: "draft"
    t.string "path"
    t.string "external_id"
    t.string "auto_title"
    t.index ["external_id"], name: "index_tracks_on_external_id", unique: true
    t.index ["release_id"], name: "index_tracks_on_release_id"
    t.index ["title"], name: "index_tracks_on_title"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "releases", "artists"
  add_foreign_key "tracks", "releases"
end
