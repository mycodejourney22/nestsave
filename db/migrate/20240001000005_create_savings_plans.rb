class CreateSavingsPlans < ActiveRecord::Migration[7.1]
  def change
    create_table :savings_plans, id: :uuid do |t|
      t.references :company_membership, null: false, foreign_key: true, type: :uuid

      t.string  :name,            null: false
      t.decimal :monthly_amount,  null: false, precision: 12, scale: 2
      t.integer :duration_months, null: false
      t.date    :start_date,      null: false
      t.date    :maturity_date,   null: false

      t.string  :status,          null: false, default: "pending"

      t.decimal :total_saved,     null: false, default: 0, precision: 12, scale: 2
      t.text    :notes

      t.uuid    :approved_by
      t.datetime :approved_at

      t.timestamps
      t.datetime :deleted_at
    end

    add_index :savings_plans, :status
    add_index :savings_plans, :deleted_at
    add_foreign_key :savings_plans, :users, column: :approved_by
  end
end
