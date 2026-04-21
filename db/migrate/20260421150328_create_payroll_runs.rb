class CreatePayrollRuns < ActiveRecord::Migration[7.1]
  def change
    create_table :payroll_runs, id: :uuid do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.integer  :month,            null: false
      t.integer  :year,             null: false
      t.string   :status,           null: false, default: "draft"
      t.uuid     :created_by,       null: false
      t.uuid     :finalised_by,     null: true
      t.datetime :finalised_at,     null: true
      t.datetime :payslips_sent_at, null: true
      t.timestamps
    end

    add_index :payroll_runs, [:company_id, :month, :year],
              unique: true, name: "idx_payroll_runs_unique"
    add_foreign_key :payroll_runs, :users, column: :created_by
    add_foreign_key :payroll_runs, :users, column: :finalised_by
  end
end
