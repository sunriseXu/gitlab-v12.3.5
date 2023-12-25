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

ActiveRecord::Schema.define(version: 2019_08_02_200655) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "container_repository_registry", id: :serial, force: :cascade do |t|
    t.integer "container_repository_id", null: false
    t.string "state"
    t.integer "retry_count", default: 0
    t.string "last_sync_failure"
    t.datetime "retry_at"
    t.datetime "last_synced_at"
    t.datetime "created_at", null: false
    t.index ["container_repository_id"], name: "index_container_repository_registry_on_repository_id", using: :btree
    t.index ["retry_at"], name: "index_container_repository_registry_on_retry_at", using: :btree
    t.index ["state"], name: "index_container_repository_registry_on_state", using: :btree
  end

  create_table "event_log_states", primary_key: "event_id", force: :cascade do |t|
    t.datetime "created_at", null: false
  end

  create_table "file_registry", id: :serial, force: :cascade do |t|
    t.string "file_type", null: false
    t.integer "file_id", null: false
    t.bigint "bytes"
    t.string "sha256"
    t.datetime "created_at", null: false
    t.boolean "success", default: false, null: false
    t.integer "retry_count"
    t.datetime "retry_at"
    t.boolean "missing_on_primary", default: false, null: false
    t.index ["file_type", "file_id"], name: "index_file_registry_on_file_type_and_file_id", unique: true, using: :btree
    t.index ["file_type"], name: "index_file_registry_on_file_type", using: :btree
    t.index ["retry_at"], name: "index_file_registry_on_retry_at", using: :btree
    t.index ["success"], name: "index_file_registry_on_success", using: :btree
  end

  create_table "job_artifact_registry", id: :serial, force: :cascade do |t|
    t.datetime_with_timezone "created_at"
    t.datetime_with_timezone "retry_at"
    t.bigint "bytes"
    t.integer "artifact_id"
    t.integer "retry_count"
    t.boolean "success"
    t.string "sha256"
    t.boolean "missing_on_primary", default: false, null: false
    t.index ["artifact_id"], name: "index_job_artifact_registry_on_artifact_id", using: :btree
    t.index ["retry_at"], name: "index_job_artifact_registry_on_retry_at", using: :btree
    t.index ["success"], name: "index_job_artifact_registry_on_success", using: :btree
  end

  create_table "project_registry", id: :serial, force: :cascade do |t|
    t.integer "project_id", null: false
    t.datetime "last_repository_synced_at"
    t.datetime "last_repository_successful_sync_at"
    t.datetime "created_at", null: false
    t.boolean "resync_repository", default: true, null: false
    t.boolean "resync_wiki", default: true, null: false
    t.datetime "last_wiki_synced_at"
    t.datetime "last_wiki_successful_sync_at"
    t.integer "repository_retry_count"
    t.datetime "repository_retry_at"
    t.boolean "force_to_redownload_repository"
    t.integer "wiki_retry_count"
    t.datetime "wiki_retry_at"
    t.boolean "force_to_redownload_wiki"
    t.string "last_repository_sync_failure"
    t.string "last_wiki_sync_failure"
    t.string "last_repository_verification_failure"
    t.string "last_wiki_verification_failure"
    t.binary "repository_verification_checksum_sha"
    t.binary "wiki_verification_checksum_sha"
    t.boolean "repository_checksum_mismatch", default: false, null: false
    t.boolean "wiki_checksum_mismatch", default: false, null: false
    t.boolean "last_repository_check_failed"
    t.datetime_with_timezone "last_repository_check_at"
    t.datetime_with_timezone "resync_repository_was_scheduled_at"
    t.datetime_with_timezone "resync_wiki_was_scheduled_at"
    t.boolean "repository_missing_on_primary"
    t.boolean "wiki_missing_on_primary"
    t.integer "repository_verification_retry_count"
    t.integer "wiki_verification_retry_count"
    t.datetime_with_timezone "last_repository_verification_ran_at"
    t.datetime_with_timezone "last_wiki_verification_ran_at"
    t.binary "repository_verification_checksum_mismatched"
    t.binary "wiki_verification_checksum_mismatched"
    t.index ["last_repository_successful_sync_at"], name: "idx_project_registry_synced_repositories_partial", where: "((resync_repository = false) AND (repository_retry_count IS NULL) AND (repository_verification_checksum_sha IS NOT NULL))", using: :btree
    t.index ["last_repository_successful_sync_at"], name: "index_project_registry_on_last_repository_successful_sync_at", using: :btree
    t.index ["last_repository_synced_at"], name: "index_project_registry_on_last_repository_synced_at", using: :btree
    t.index ["project_id"], name: "idx_project_registry_on_repo_checksums_and_failure_partial", where: "((repository_verification_checksum_sha IS NULL) AND (last_repository_verification_failure IS NULL))", using: :btree
    t.index ["project_id"], name: "idx_project_registry_on_repository_failure_partial", where: "(last_repository_verification_failure IS NOT NULL)", using: :btree
    t.index ["project_id"], name: "idx_project_registry_on_wiki_checksums_and_failure_partial", where: "((wiki_verification_checksum_sha IS NULL) AND (last_wiki_verification_failure IS NULL))", using: :btree
    t.index ["project_id"], name: "idx_project_registry_on_wiki_failure_partial", where: "(last_wiki_verification_failure IS NOT NULL)", using: :btree
    t.index ["project_id"], name: "idx_repository_checksum_mismatch", where: "(repository_checksum_mismatch = true)", using: :btree
    t.index ["project_id"], name: "idx_wiki_checksum_mismatch", where: "(wiki_checksum_mismatch = true)", using: :btree
    t.index ["project_id"], name: "index_project_registry_on_project_id", unique: true, using: :btree
    t.index ["repository_retry_at"], name: "index_project_registry_on_repository_retry_at", using: :btree
    t.index ["repository_retry_count"], name: "idx_project_registry_failed_repositories_partial", where: "((repository_retry_count > 0) OR (last_repository_verification_failure IS NOT NULL) OR repository_checksum_mismatch)", using: :btree
    t.index ["repository_retry_count"], name: "idx_project_registry_pending_repositories_partial", where: "((repository_retry_count IS NULL) AND (last_repository_successful_sync_at IS NOT NULL) AND ((resync_repository = true) OR ((repository_verification_checksum_sha IS NULL) AND (last_repository_verification_failure IS NULL))))", using: :btree
    t.index ["repository_verification_checksum_sha"], name: "idx_project_registry_on_repository_checksum_sha_partial", where: "(repository_verification_checksum_sha IS NULL)", using: :btree
    t.index ["resync_repository"], name: "index_project_registry_on_resync_repository", using: :btree
    t.index ["resync_wiki"], name: "index_project_registry_on_resync_wiki", using: :btree
    t.index ["wiki_retry_at"], name: "index_project_registry_on_wiki_retry_at", using: :btree
    t.index ["wiki_verification_checksum_sha"], name: "idx_project_registry_on_wiki_checksum_sha_partial", where: "(wiki_verification_checksum_sha IS NULL)", using: :btree
  end

end
