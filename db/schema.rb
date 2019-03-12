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

ActiveRecord::Schema.define(version: 2018_11_18_211833) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "backups", force: :cascade do |t|
    t.integer "user_id"
    t.string "location"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "comment"
  end

  create_table "items", force: :cascade do |t|
    t.integer "repo_id"
    t.integer "merkle_id"
    t.text "value"
    t.string "oyd_hash"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "oyd_source_pile_id"
  end

  create_table "logs", force: :cascade do |t|
    t.integer "user_id"
    t.integer "plugin_id"
    t.string "identifier"
    t.text "message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "merkles", force: :cascade do |t|
    t.text "payload"
    t.string "root_hash"
    t.string "oyd_transaction"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "merkle_tree"
  end

  create_table "oauth_access_grants", force: :cascade do |t|
    t.integer "resource_owner_id", null: false
    t.bigint "application_id", null: false
    t.string "token", null: false
    t.integer "expires_in", null: false
    t.text "redirect_uri", null: false
    t.datetime "created_at", null: false
    t.datetime "revoked_at"
    t.string "scopes"
    t.index ["application_id"], name: "index_oauth_access_grants_on_application_id"
    t.index ["token"], name: "index_oauth_access_grants_on_token", unique: true
  end

  create_table "oauth_access_tokens", force: :cascade do |t|
    t.integer "resource_owner_id"
    t.bigint "application_id"
    t.string "token", null: false
    t.string "refresh_token"
    t.integer "expires_in"
    t.datetime "revoked_at"
    t.datetime "created_at", null: false
    t.string "scopes"
    t.string "previous_refresh_token", default: "", null: false
    t.index ["application_id"], name: "index_oauth_access_tokens_on_application_id"
    t.index ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true
    t.index ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_tokens_on_token", unique: true
  end

  create_table "oauth_applications", force: :cascade do |t|
    t.string "name", null: false
    t.string "uid", null: false
    t.string "secret", null: false
    t.text "redirect_uri", null: false
    t.string "scopes", default: "", null: false
    t.string "identifier"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "owner_id"
    t.string "owner_type"
    t.text "perms"
    t.string "oyd_version"
    t.string "description"
    t.string "language"
    t.boolean "assist_update"
    t.boolean "confidential", default: true, null: false
    t.index ["owner_id", "owner_type"], name: "index_oauth_applications_on_owner_id_and_owner_type"
    t.index ["uid"], name: "index_oauth_applications_on_uid", unique: true
  end

  create_table "oyd_answers", force: :cascade do |t|
    t.integer "plugin_id"
    t.string "name"
    t.string "identifier"
    t.string "category"
    t.string "info_url"
    t.text "repos"
    t.integer "answer_order"
    t.text "answer_view"
    t.text "answer_logic"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "short"
  end

  create_table "oyd_reports", force: :cascade do |t|
    t.integer "plugin_id"
    t.string "identifier"
    t.text "data_prep"
    t.text "report_view"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "current"
    t.string "name"
    t.string "info_url"
    t.text "data_snippet"
    t.integer "report_order"
    t.text "repos"
  end

  create_table "oyd_source_piles", force: :cascade do |t|
    t.integer "oyd_source_id"
    t.text "content"
    t.string "email"
    t.text "signature"
    t.text "verification"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "oyd_source_repos", force: :cascade do |t|
    t.integer "oyd_source_id"
    t.integer "repo_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "stats"
  end

  create_table "oyd_sources", force: :cascade do |t|
    t.integer "plugin_id"
    t.string "name"
    t.string "description"
    t.string "source_type"
    t.text "config"
    t.text "config_values"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "configured"
    t.boolean "assist_check"
    t.string "identifier"
    t.integer "inactive_duration"
    t.string "inactive_text"
    t.boolean "inactive_check"
  end

  create_table "oyd_tasks", force: :cascade do |t|
    t.integer "plugin_id"
    t.string "identifier"
    t.text "command"
    t.string "schedule"
    t.datetime "next_run"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "oyd_views", force: :cascade do |t|
    t.integer "plugin_id"
    t.integer "plugin_detail_id"
    t.string "name"
    t.string "identifier"
    t.string "url"
    t.string "view_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "permissions", force: :cascade do |t|
    t.integer "plugin_id"
    t.string "repo_identifier"
    t.integer "perm_type"
    t.boolean "perm_allow"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "plugin_assists", force: :cascade do |t|
    t.integer "user_id"
    t.string "identifier"
    t.boolean "assist"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "plugin_details", force: :cascade do |t|
    t.string "description"
    t.string "info_url"
    t.text "picture"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "identifier"
  end

  create_table "repos", force: :cascade do |t|
    t.integer "user_id"
    t.string "name"
    t.string "identifier"
    t.string "public_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.string "full_name"
    t.string "language"
    t.string "frontend_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "recovery_password_digest"
    t.string "password_key"
    t.string "recovery_password_key"
    t.boolean "email_notif"
    t.boolean "assist_relax"
    t.integer "last_item_count"
    t.string "remember_digest"
    t.string "reset_digest"
    t.datetime "reset_sent_at"
    t.string "app_nonce"
    t.string "app_cipher"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "oauth_access_grants", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_tokens", "oauth_applications", column: "application_id"
end
