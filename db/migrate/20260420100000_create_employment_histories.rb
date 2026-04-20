class CreateEmploymentHistories < ActiveRecord::Migration[7.1]
  def change
    create_table :employment_histories, id: :uuid do |t|
      t.references :employee_profile, null: false, foreign_key: true, type: :uuid
      t.string  :company_name,       null: false
      t.string  :job_title,          null: false
      t.date    :start_date,         null: false
      t.date    :end_date
      t.string  :location
      t.string  :reason_for_leaving
      t.text    :notes
      t.timestamps
    end
  end
end
