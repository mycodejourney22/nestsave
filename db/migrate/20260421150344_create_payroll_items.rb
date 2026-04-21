class CreatePayrollItems < ActiveRecord::Migration[7.1]
  def change
    create_table :payroll_items, id: :uuid do |t|
      t.references :payroll_entry, null: false, foreign_key: true, type: :uuid
      t.string  :category,         null: false
      t.string  :item_type,        null: false
      t.string  :label,            null: false
      t.decimal :amount,           null: false, default: 0, precision: 14, scale: 2
      t.string  :notes,            null: true
      t.boolean :auto_generated,   null: false, default: false
      t.boolean :editable,         null: false, default: true
      t.timestamps
    end

    add_index :payroll_items, [:payroll_entry_id, :item_type]
  end
end
