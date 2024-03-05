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

ActiveRecord::Schema[7.0].define(version: 2024_02_23_150228) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_stat_statements"
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "active_storage_attachments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.uuid "record_id", null: false
    t.uuid "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
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

  create_table "active_storage_variant_records", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "class_members", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "school_class_id", null: false
    t.uuid "student_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["school_class_id", "student_id"], name: "index_class_members_on_school_class_id_and_student_id", unique: true
    t.index ["school_class_id"], name: "index_class_members_on_school_class_id"
    t.index ["student_id"], name: "index_class_members_on_student_id"
  end

  create_table "components", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "project_id"
    t.string "name", null: false
    t.string "extension", null: false
    t.string "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "default", default: false, null: false
    t.index ["project_id"], name: "index_components_on_project_id"
  end

  create_table "good_job_batches", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.jsonb "serialized_properties"
    t.text "on_finish"
    t.text "on_success"
    t.text "on_discard"
    t.text "callback_queue_name"
    t.integer "callback_priority"
    t.datetime "enqueued_at"
    t.datetime "discarded_at"
    t.datetime "finished_at"
  end

  create_table "good_job_processes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "state"
  end

  create_table "good_job_settings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "key"
    t.jsonb "value"
    t.index ["key"], name: "index_good_job_settings_on_key", unique: true
  end

  create_table "good_jobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "queue_name"
    t.integer "priority"
    t.jsonb "serialized_params"
    t.datetime "scheduled_at"
    t.datetime "performed_at"
    t.datetime "finished_at"
    t.text "error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "active_job_id"
    t.text "concurrency_key"
    t.text "cron_key"
    t.uuid "retried_good_job_id"
    t.datetime "cron_at"
    t.uuid "batch_id"
    t.uuid "batch_callback_id"
    t.index ["active_job_id", "created_at"], name: "index_good_jobs_on_active_job_id_and_created_at"
    t.index ["active_job_id"], name: "index_good_jobs_on_active_job_id"
    t.index ["batch_callback_id"], name: "index_good_jobs_on_batch_callback_id", where: "(batch_callback_id IS NOT NULL)"
    t.index ["batch_id"], name: "index_good_jobs_on_batch_id", where: "(batch_id IS NOT NULL)"
    t.index ["concurrency_key"], name: "index_good_jobs_on_concurrency_key_when_unfinished", where: "(finished_at IS NULL)"
    t.index ["cron_key", "created_at"], name: "index_good_jobs_on_cron_key_and_created_at"
    t.index ["cron_key", "cron_at"], name: "index_good_jobs_on_cron_key_and_cron_at", unique: true
    t.index ["finished_at"], name: "index_good_jobs_jobs_on_finished_at", where: "((retried_good_job_id IS NULL) AND (finished_at IS NOT NULL))"
    t.index ["priority", "created_at"], name: "index_good_jobs_jobs_on_priority_created_at_when_unfinished", order: { priority: "DESC NULLS LAST" }, where: "(finished_at IS NULL)"
    t.index ["queue_name", "scheduled_at"], name: "index_good_jobs_on_queue_name_and_scheduled_at", where: "(finished_at IS NULL)"
    t.index ["scheduled_at"], name: "index_good_jobs_on_scheduled_at", where: "(finished_at IS NULL)"
  end

  create_table "lessons", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "school_id"
    t.uuid "school_class_id"
    t.uuid "copied_from_id"
    t.uuid "user_id", null: false
    t.string "name", null: false
    t.string "description"
    t.string "visibility", default: "private", null: false
    t.datetime "due_date"
    t.datetime "archived_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["archived_at"], name: "index_lessons_on_archived_at"
    t.index ["copied_from_id"], name: "index_lessons_on_copied_from_id"
    t.index ["name"], name: "index_lessons_on_name"
    t.index ["school_class_id"], name: "index_lessons_on_school_class_id"
    t.index ["school_id"], name: "index_lessons_on_school_id"
    t.index ["user_id"], name: "index_lessons_on_user_id"
    t.index ["visibility"], name: "index_lessons_on_visibility"
  end

  create_table "project_errors", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "project_id"
    t.string "error", null: false
    t.string "error_type"
    t.uuid "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_project_errors_on_project_id"
  end

  create_table "projects", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id"
    t.string "name"
    t.string "identifier", null: false
    t.string "project_type", default: "python", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "remixed_from_id"
    t.string "locale"
    t.string "remix_origin"
    t.uuid "school_id"
    t.uuid "lesson_id"
    t.index ["identifier", "locale"], name: "index_projects_on_identifier_and_locale", unique: true
    t.index ["identifier"], name: "index_projects_on_identifier"
    t.index ["lesson_id"], name: "index_projects_on_lesson_id"
    t.index ["remixed_from_id"], name: "index_projects_on_remixed_from_id"
    t.index ["school_id"], name: "index_projects_on_school_id"
  end

  create_table "school_classes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "school_id", null: false
    t.uuid "teacher_id", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["school_id", "teacher_id"], name: "index_school_classes_on_school_id_and_teacher_id"
    t.index ["school_id"], name: "index_school_classes_on_school_id"
  end

  create_table "schools", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "reference"
    t.string "address_line_1", null: false
    t.string "address_line_2"
    t.string "municipality", null: false
    t.string "administrative_area"
    t.string "postal_code"
    t.string "country_code", null: false
    t.datetime "verified_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["reference"], name: "index_schools_on_reference", unique: true
  end

  create_table "school_classes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "school_id", null: false
    t.uuid "teacher_id", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["school_id", "teacher_id"], name: "index_school_classes_on_school_id_and_teacher_id"
    t.index ["school_id"], name: "index_school_classes_on_school_id"
  end

  create_table "schools", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "reference"
    t.string "address_line_1", null: false
    t.string "address_line_2"
    t.string "municipality", null: false
    t.string "administrative_area"
    t.string "postal_code"
    t.string "country_code", null: false
    t.datetime "verified_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["reference"], name: "index_schools_on_reference", unique: true
  end

  create_table "words", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "word"
    t.index ["word"], name: "index_words_on_word"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "class_members", "school_classes"
  add_foreign_key "components", "projects"
  add_foreign_key "lessons", "lessons", column: "copied_from_id"
  add_foreign_key "lessons", "school_classes"
  add_foreign_key "lessons", "schools"
  add_foreign_key "project_errors", "projects"
  add_foreign_key "projects", "lessons"
  add_foreign_key "projects", "schools"
  add_foreign_key "school_classes", "schools"
end
