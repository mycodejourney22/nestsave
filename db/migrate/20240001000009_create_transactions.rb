class CreateTransactions < ActiveRecord::Migration[7.1]
  def change
    create_table :transactions, id: :uuid do |t|
      t.references :company_membership, null: false, foreign_key: true, type: :uuid

      t.string :reference_type, null: false
      t.uuid   :reference_id,   null: false

      t.string  :kind,         null: false
      t.decimal :amount,       null: false, precision: 12, scale: 2
      t.string  :status,       null: false, default: "completed"

      t.text    :description
      t.date    :period_month,  null: false

      t.timestamps
    end

    add_index :transactions, [:reference_type, :reference_id]
    add_index :transactions, :kind
    add_index :transactions, :period_month
  end
end
