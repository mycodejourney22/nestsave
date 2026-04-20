class CreateLeaveTypes < ActiveRecord::Migration[7.1]
  def change
    create_table :leave_types, id: :uuid do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.string  :name,             null: false
      t.string  :category,         null: false
      t.integer :default_days,     null: false, default: 0
      t.boolean :requires_balance, null: false, default: true
      t.boolean :accrues_monthly,  null: false, default: false
      t.boolean :active,           null: false, default: true
      t.timestamps
    end

    add_index :leave_types, [:company_id, :name], unique: true
  end
end
