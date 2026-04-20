class CreateSalaryAdvances < ActiveRecord::Migration[7.1]
  def change
    create_table :salary_advances, id: :uuid do |t|
      t.references :company_membership, null: false, foreign_key: true, type: :uuid

      t.decimal :amount,             null: false, precision: 12, scale: 2
      t.text    :reason,             null: false
      t.integer :repayment_months,   null: false
      t.decimal :monthly_instalment, null: false, precision: 12, scale: 2

      t.string  :status, null: false, default: "pending"

      t.uuid    :reviewed_by
      t.text    :review_note
      t.datetime :applied_at,   null: false
      t.datetime :reviewed_at
      t.datetime :disbursed_at

      t.timestamps
      t.datetime :deleted_at
    end

    add_index :salary_advances, :status
    add_index :salary_advances, :deleted_at
    add_foreign_key :salary_advances, :users, column: :reviewed_by
  end
end
