class CreateEmployeeProfiles < ActiveRecord::Migration[7.1]
  def change
    create_table :employee_profiles, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :company_membership, type: :uuid, null: false, foreign_key: true, index: { unique: true }
      t.string  :employee_number,          null: false
      t.string  :preferred_name
      t.string  :gender
      t.date    :date_of_birth
      t.string  :phone
      t.string  :personal_email
      t.string  :employment_type,          null: false, default: "full_time"
      t.string  :department
      t.string  :job_title
      t.date    :employment_start_date,    null: false
      t.date    :employment_end_date
      t.string  :right_to_work_status
      t.date    :right_to_work_expiry
      t.string  :address_line_1
      t.string  :address_line_2
      t.string  :city
      t.string  :postcode
      t.string  :country,                  default: "United Kingdom"
      t.string  :nationality
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :employee_profiles, :employee_number, unique: true
    add_index :employee_profiles, :deleted_at
  end
end
