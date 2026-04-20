class CreateLeaveBalances < ActiveRecord::Migration[7.1]
  def change
    create_table :leave_balances, id: :uuid do |t|
      t.references :employee_profile, null: false, foreign_key: true, type: :uuid
      t.references :leave_type,       null: false, foreign_key: true, type: :uuid
      t.integer :year,          null: false
      t.decimal :total_days,    null: false, default: 0, precision: 5, scale: 1
      t.decimal :accrued_days,  null: false, default: 0, precision: 5, scale: 1
      t.decimal :used_days,     null: false, default: 0, precision: 5, scale: 1
      t.decimal :override_days, null: false, default: 0, precision: 5, scale: 1
      t.uuid    :overridden_by, null: true
      t.datetime :overridden_at, null: true
      t.timestamps
    end

    add_index :leave_balances, [:employee_profile_id, :leave_type_id, :year],
              unique: true, name: "idx_leave_balances_unique"
    add_foreign_key :leave_balances, :users, column: :overridden_by
  end
end
