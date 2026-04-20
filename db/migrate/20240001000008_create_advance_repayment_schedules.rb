class CreateAdvanceRepaymentSchedules < ActiveRecord::Migration[7.1]
  def change
    create_table :advance_repayment_schedules, id: :uuid do |t|
      t.references :salary_advance, null: false, foreign_key: true, type: :uuid

      t.integer  :instalment_number, null: false
      t.decimal  :amount,            null: false, precision: 12, scale: 2
      t.date     :due_date,          null: false
      t.string   :status,            null: false, default: "pending"

      t.datetime :paid_at

      t.timestamps
    end

    add_index :advance_repayment_schedules,
              [:salary_advance_id, :instalment_number],
              unique: true,
              name: "idx_repayment_schedule_unique"
    add_index :advance_repayment_schedules, :due_date
    add_index :advance_repayment_schedules, :status
  end
end
