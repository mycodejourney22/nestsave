class CreatePayrollEntries < ActiveRecord::Migration[7.1]
  def change
    create_table :payroll_entries, id: :uuid do |t|
      t.references :payroll_run,       null: false, foreign_key: true, type: :uuid
      t.references :employee_profile,  null: false, foreign_key: true, type: :uuid
      t.decimal :base_salary,          null: false, precision: 14, scale: 2
      t.decimal :total_earnings,       null: false, default: 0, precision: 14, scale: 2
      t.decimal :total_deductions,     null: false, default: 0, precision: 14, scale: 2
      t.decimal :net_pay,              null: false, default: 0, precision: 14, scale: 2
      t.boolean :locked,               null: false, default: false
      t.timestamps
    end

    add_index :payroll_entries, [:payroll_run_id, :employee_profile_id],
              unique: true, name: "idx_payroll_entries_unique"
  end
end
