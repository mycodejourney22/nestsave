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

ActiveRecord::Schema[7.1].define(version: 2026_04_22_154947) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.uuid "record_id", null: false
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

  create_table "advance_repayment_schedules", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "salary_advance_id", null: false
    t.integer "instalment_number", null: false
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.date "due_date", null: false
    t.string "status", default: "pending", null: false
    t.datetime "paid_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["due_date"], name: "index_advance_repayment_schedules_on_due_date"
    t.index ["salary_advance_id", "instalment_number"], name: "idx_repayment_schedule_unique", unique: true
    t.index ["salary_advance_id"], name: "index_advance_repayment_schedules_on_salary_advance_id"
    t.index ["status"], name: "index_advance_repayment_schedules_on_status"
  end

  create_table "bank_details", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "employee_profile_id", null: false
    t.string "bank_name", null: false
    t.string "account_name", null: false
    t.string "account_number", null: false
    t.string "sort_code", null: false
    t.boolean "active", default: true, null: false
    t.uuid "recorded_by", null: false
    t.datetime "created_at", null: false
    t.index ["employee_profile_id", "active"], name: "index_bank_details_on_employee_profile_id_and_active"
    t.index ["employee_profile_id"], name: "index_bank_details_on_employee_profile_id"
  end

  create_table "companies", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.string "payroll_email", null: false
    t.string "timezone", default: "UTC", null: false
    t.integer "payroll_day", default: 25, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.string "country"
    t.string "currency"
    t.string "currency_symbol"
    t.index ["deleted_at"], name: "index_companies_on_deleted_at"
    t.index ["slug"], name: "index_companies_on_slug", unique: true
  end

  create_table "company_memberships", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id"
    t.uuid "company_id", null: false
    t.string "role", default: "employee", null: false
    t.string "status", default: "active", null: false
    t.uuid "invited_by"
    t.datetime "joined_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.string "invited_name"
    t.string "invited_email"
    t.string "invitation_token"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.uuid "team_id"
    t.index ["company_id"], name: "index_company_memberships_on_company_id"
    t.index ["deleted_at"], name: "index_company_memberships_on_deleted_at"
    t.index ["invitation_token"], name: "index_company_memberships_on_invitation_token", unique: true, where: "(invitation_token IS NOT NULL)"
    t.index ["invited_email"], name: "index_company_memberships_on_invited_email"
    t.index ["role"], name: "index_company_memberships_on_role"
    t.index ["status"], name: "index_company_memberships_on_status"
    t.index ["team_id"], name: "index_company_memberships_on_team_id"
    t.index ["user_id", "company_id"], name: "index_company_memberships_on_user_id_and_company_id", unique: true, where: "(deleted_at IS NULL)"
    t.index ["user_id"], name: "index_company_memberships_on_user_id"
  end

  create_table "departments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.string "name", null: false
    t.string "color", default: "#1D9E75"
    t.boolean "active", default: true, null: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "name"], name: "index_departments_on_company_id_and_name", unique: true, where: "(deleted_at IS NULL)"
    t.index ["company_id"], name: "index_departments_on_company_id"
    t.index ["deleted_at"], name: "index_departments_on_deleted_at"
  end

  create_table "documents", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "employee_profile_id", null: false
    t.string "title", null: false
    t.string "category", default: "other", null: false
    t.text "notes"
    t.uuid "uploaded_by", null: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.index ["deleted_at"], name: "index_documents_on_deleted_at"
    t.index ["employee_profile_id"], name: "index_documents_on_employee_profile_id"
  end

  create_table "emergency_contacts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "employee_profile_id", null: false
    t.string "full_name", null: false
    t.string "relationship", null: false
    t.string "phone", null: false
    t.string "email"
    t.boolean "primary", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["employee_profile_id"], name: "index_emergency_contacts_on_employee_profile_id"
  end

  create_table "employee_profiles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_membership_id", null: false
    t.string "employee_number", null: false
    t.string "preferred_name"
    t.string "gender"
    t.date "date_of_birth"
    t.string "phone"
    t.string "personal_email"
    t.string "employment_type", default: "full_time", null: false
    t.string "department"
    t.string "job_title"
    t.date "employment_start_date", null: false
    t.date "employment_end_date"
    t.string "right_to_work_status"
    t.date "right_to_work_expiry"
    t.string "address_line_1"
    t.string "address_line_2"
    t.string "city"
    t.string "postcode"
    t.string "country", default: "United Kingdom"
    t.string "nationality"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "department_id"
    t.uuid "team_id"
    t.index ["company_membership_id"], name: "index_employee_profiles_on_company_membership_id", unique: true
    t.index ["deleted_at"], name: "index_employee_profiles_on_deleted_at"
    t.index ["department_id"], name: "index_employee_profiles_on_department_id"
    t.index ["employee_number"], name: "index_employee_profiles_on_employee_number", unique: true
    t.index ["team_id"], name: "index_employee_profiles_on_team_id"
  end

  create_table "employee_references", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "employee_profile_id", null: false
    t.string "referee_name", null: false
    t.string "organisation"
    t.string "relationship", null: false
    t.string "email"
    t.string "phone"
    t.string "status", default: "not_requested", null: false
    t.date "requested_on"
    t.date "received_on"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["employee_profile_id"], name: "index_employee_references_on_employee_profile_id"
    t.index ["status"], name: "index_employee_references_on_status"
  end

  create_table "employment_histories", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "employee_profile_id", null: false
    t.string "company_name", null: false
    t.string "job_title", null: false
    t.date "start_date", null: false
    t.date "end_date"
    t.string "location"
    t.string "reason_for_leaving"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["employee_profile_id"], name: "index_employment_histories_on_employee_profile_id"
  end

  create_table "leave_balances", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "employee_profile_id", null: false
    t.uuid "leave_type_id", null: false
    t.integer "year", null: false
    t.decimal "total_days", precision: 5, scale: 1, default: "0.0", null: false
    t.decimal "accrued_days", precision: 5, scale: 1, default: "0.0", null: false
    t.decimal "used_days", precision: 5, scale: 1, default: "0.0", null: false
    t.decimal "override_days", precision: 5, scale: 1, default: "0.0", null: false
    t.uuid "overridden_by"
    t.datetime "overridden_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["employee_profile_id", "leave_type_id", "year"], name: "idx_leave_balances_unique", unique: true
    t.index ["employee_profile_id"], name: "index_leave_balances_on_employee_profile_id"
    t.index ["leave_type_id"], name: "index_leave_balances_on_leave_type_id"
  end

  create_table "leave_requests", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "employee_profile_id", null: false
    t.uuid "leave_type_id", null: false
    t.uuid "leave_balance_id"
    t.date "start_date", null: false
    t.date "end_date", null: false
    t.integer "total_days", null: false
    t.text "reason"
    t.string "status", default: "pending", null: false
    t.uuid "reviewed_by"
    t.text "review_note"
    t.datetime "requested_at", null: false
    t.datetime "reviewed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["employee_profile_id"], name: "index_leave_requests_on_employee_profile_id"
    t.index ["leave_balance_id"], name: "index_leave_requests_on_leave_balance_id"
    t.index ["leave_type_id"], name: "index_leave_requests_on_leave_type_id"
    t.index ["start_date"], name: "index_leave_requests_on_start_date"
    t.index ["status"], name: "index_leave_requests_on_status"
  end

  create_table "leave_types", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.string "name", null: false
    t.string "category", null: false
    t.integer "default_days", default: 0, null: false
    t.boolean "requires_balance", default: true, null: false
    t.boolean "accrues_monthly", default: false, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "name"], name: "index_leave_types_on_company_id_and_name", unique: true
    t.index ["company_id"], name: "index_leave_types_on_company_id"
  end

  create_table "notifications", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "notifiable_type", null: false
    t.uuid "notifiable_id", null: false
    t.string "channel", default: "email", null: false
    t.string "event", null: false
    t.boolean "sent", default: false, null: false
    t.datetime "sent_at"
    t.boolean "read", default: false, null: false
    t.datetime "read_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable_type_and_notifiable_id"
    t.index ["sent"], name: "index_notifications_on_sent"
    t.index ["user_id", "read"], name: "index_notifications_on_user_id_and_read"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "payroll_entries", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "payroll_run_id", null: false
    t.uuid "employee_profile_id", null: false
    t.decimal "base_salary", precision: 14, scale: 2, null: false
    t.decimal "total_earnings", precision: 14, scale: 2, default: "0.0", null: false
    t.decimal "total_deductions", precision: 14, scale: 2, default: "0.0", null: false
    t.decimal "net_pay", precision: 14, scale: 2, default: "0.0", null: false
    t.boolean "locked", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["employee_profile_id"], name: "index_payroll_entries_on_employee_profile_id"
    t.index ["payroll_run_id", "employee_profile_id"], name: "idx_payroll_entries_unique", unique: true
    t.index ["payroll_run_id"], name: "index_payroll_entries_on_payroll_run_id"
  end

  create_table "payroll_items", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "payroll_entry_id", null: false
    t.string "category", null: false
    t.string "item_type", null: false
    t.string "label", null: false
    t.decimal "amount", precision: 14, scale: 2, default: "0.0", null: false
    t.string "notes"
    t.boolean "auto_generated", default: false, null: false
    t.boolean "editable", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["payroll_entry_id", "item_type"], name: "index_payroll_items_on_payroll_entry_id_and_item_type"
    t.index ["payroll_entry_id"], name: "index_payroll_items_on_payroll_entry_id"
  end

  create_table "payroll_runs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.integer "month", null: false
    t.integer "year", null: false
    t.string "status", default: "draft", null: false
    t.uuid "created_by", null: false
    t.uuid "finalised_by"
    t.datetime "finalised_at"
    t.datetime "payslips_sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "month", "year"], name: "idx_payroll_runs_unique", unique: true
    t.index ["company_id"], name: "index_payroll_runs_on_company_id"
  end

  create_table "rota_entries", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "rota_id", null: false
    t.uuid "employee_profile_id", null: false
    t.date "work_date", null: false
    t.time "start_time"
    t.time "end_time"
    t.string "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["employee_profile_id"], name: "index_rota_entries_on_employee_profile_id"
    t.index ["rota_id", "employee_profile_id", "work_date"], name: "idx_rota_entries_unique", unique: true
    t.index ["rota_id"], name: "index_rota_entries_on_rota_id"
  end

  create_table "rotas", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "team_id", null: false
    t.uuid "created_by", null: false
    t.date "week_start", null: false
    t.date "week_end", null: false
    t.string "status", default: "draft", null: false
    t.datetime "published_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id", "week_start"], name: "index_rotas_on_team_id_and_week_start", unique: true
    t.index ["team_id"], name: "index_rotas_on_team_id"
  end

  create_table "salary_advances", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_membership_id", null: false
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.text "reason", null: false
    t.integer "repayment_months", null: false
    t.decimal "monthly_instalment", precision: 12, scale: 2, null: false
    t.string "status", default: "pending", null: false
    t.uuid "reviewed_by"
    t.text "review_note"
    t.datetime "applied_at", null: false
    t.datetime "reviewed_at"
    t.datetime "disbursed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["company_membership_id"], name: "index_salary_advances_on_company_membership_id"
    t.index ["deleted_at"], name: "index_salary_advances_on_deleted_at"
    t.index ["status"], name: "index_salary_advances_on_status"
  end

  create_table "salary_histories", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "employee_profile_id", null: false
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.string "currency", default: "GBP", null: false
    t.string "reason"
    t.date "effective_date", null: false
    t.uuid "changed_by", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.index ["effective_date"], name: "index_salary_histories_on_effective_date"
    t.index ["employee_profile_id"], name: "index_salary_histories_on_employee_profile_id"
  end

  create_table "savings_plans", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_membership_id", null: false
    t.string "name", null: false
    t.decimal "monthly_amount", precision: 12, scale: 2, null: false
    t.integer "duration_months", null: false
    t.date "start_date", null: false
    t.date "maturity_date", null: false
    t.string "status", default: "pending", null: false
    t.decimal "total_saved", precision: 12, scale: 2, default: "0.0", null: false
    t.text "notes"
    t.uuid "approved_by"
    t.datetime "approved_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["company_membership_id"], name: "index_savings_plans_on_company_membership_id"
    t.index ["deleted_at"], name: "index_savings_plans_on_deleted_at"
    t.index ["status"], name: "index_savings_plans_on_status"
  end

  create_table "teams", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.string "name", null: false
    t.string "description"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["company_id", "name"], name: "index_teams_on_company_id_and_name", unique: true, where: "(deleted_at IS NULL)"
    t.index ["company_id"], name: "index_teams_on_company_id"
    t.index ["deleted_at"], name: "index_teams_on_deleted_at"
  end

  create_table "transactions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_membership_id", null: false
    t.string "reference_type", null: false
    t.uuid "reference_id", null: false
    t.string "kind", null: false
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.string "status", default: "completed", null: false
    t.text "description"
    t.date "period_month", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_membership_id"], name: "index_transactions_on_company_membership_id"
    t.index ["kind"], name: "index_transactions_on_kind"
    t.index ["period_month"], name: "index_transactions_on_period_month"
    t.index ["reference_type", "reference_id"], name: "index_transactions_on_reference_type_and_reference_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "full_name", null: false
    t.string "email", null: false
    t.string "encrypted_password", default: "", null: false
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_users_on_deleted_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "withdrawal_requests", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "savings_plan_id", null: false
    t.uuid "company_membership_id", null: false
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.text "reason"
    t.string "status", default: "pending", null: false
    t.uuid "reviewed_by"
    t.text "review_note"
    t.datetime "requested_at", null: false
    t.datetime "reviewed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_membership_id"], name: "index_withdrawal_requests_on_company_membership_id"
    t.index ["savings_plan_id"], name: "index_withdrawal_requests_on_savings_plan_id"
    t.index ["status"], name: "index_withdrawal_requests_on_status"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "advance_repayment_schedules", "salary_advances"
  add_foreign_key "bank_details", "employee_profiles"
  add_foreign_key "bank_details", "users", column: "recorded_by"
  add_foreign_key "company_memberships", "companies"
  add_foreign_key "company_memberships", "teams"
  add_foreign_key "company_memberships", "users"
  add_foreign_key "company_memberships", "users", column: "invited_by"
  add_foreign_key "departments", "companies"
  add_foreign_key "documents", "employee_profiles"
  add_foreign_key "documents", "users", column: "uploaded_by"
  add_foreign_key "emergency_contacts", "employee_profiles"
  add_foreign_key "employee_profiles", "company_memberships"
  add_foreign_key "employee_profiles", "departments"
  add_foreign_key "employee_profiles", "teams"
  add_foreign_key "employee_references", "employee_profiles"
  add_foreign_key "employment_histories", "employee_profiles"
  add_foreign_key "leave_balances", "employee_profiles"
  add_foreign_key "leave_balances", "leave_types"
  add_foreign_key "leave_balances", "users", column: "overridden_by"
  add_foreign_key "leave_requests", "employee_profiles"
  add_foreign_key "leave_requests", "leave_balances"
  add_foreign_key "leave_requests", "leave_types"
  add_foreign_key "leave_requests", "users", column: "reviewed_by"
  add_foreign_key "leave_types", "companies"
  add_foreign_key "notifications", "users"
  add_foreign_key "payroll_entries", "employee_profiles"
  add_foreign_key "payroll_entries", "payroll_runs"
  add_foreign_key "payroll_items", "payroll_entries"
  add_foreign_key "payroll_runs", "companies"
  add_foreign_key "payroll_runs", "users", column: "created_by"
  add_foreign_key "payroll_runs", "users", column: "finalised_by"
  add_foreign_key "rota_entries", "employee_profiles"
  add_foreign_key "rota_entries", "rotas"
  add_foreign_key "rotas", "teams"
  add_foreign_key "rotas", "users", column: "created_by"
  add_foreign_key "salary_advances", "company_memberships"
  add_foreign_key "salary_advances", "users", column: "reviewed_by"
  add_foreign_key "salary_histories", "employee_profiles"
  add_foreign_key "salary_histories", "users", column: "changed_by"
  add_foreign_key "savings_plans", "company_memberships"
  add_foreign_key "savings_plans", "users", column: "approved_by"
  add_foreign_key "teams", "companies"
  add_foreign_key "transactions", "company_memberships"
  add_foreign_key "withdrawal_requests", "company_memberships"
  add_foreign_key "withdrawal_requests", "savings_plans"
  add_foreign_key "withdrawal_requests", "users", column: "reviewed_by"
end
