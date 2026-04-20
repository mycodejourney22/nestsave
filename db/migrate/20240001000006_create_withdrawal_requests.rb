class CreateWithdrawalRequests < ActiveRecord::Migration[7.1]
  def change
    create_table :withdrawal_requests, id: :uuid do |t|
      t.references :savings_plan,       null: false, foreign_key: true, type: :uuid
      t.references :company_membership, null: false, foreign_key: true, type: :uuid

      t.decimal :amount,       null: false, precision: 12, scale: 2
      t.text    :reason
      t.string  :status,       null: false, default: "pending"

      t.uuid    :reviewed_by
      t.text    :review_note
      t.datetime :requested_at, null: false
      t.datetime :reviewed_at

      t.timestamps
    end

    add_index :withdrawal_requests, :status
    add_foreign_key :withdrawal_requests, :users, column: :reviewed_by
  end
end
