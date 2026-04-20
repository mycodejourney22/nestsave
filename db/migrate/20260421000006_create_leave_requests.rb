class CreateLeaveRequests < ActiveRecord::Migration[7.1]
  def change
    create_table :leave_requests, id: :uuid do |t|
      t.references :employee_profile, null: false, foreign_key: true, type: :uuid
      t.references :leave_type,       null: false, foreign_key: true, type: :uuid
      t.references :leave_balance,    null: true,  foreign_key: true, type: :uuid
      t.date    :start_date,    null: false
      t.date    :end_date,      null: false
      t.integer :total_days,    null: false
      t.text    :reason,        null: true
      t.string  :status,        null: false, default: "pending"
      t.uuid    :reviewed_by,   null: true
      t.text    :review_note,   null: true
      t.datetime :requested_at, null: false
      t.datetime :reviewed_at,  null: true
      t.timestamps
    end

    add_index :leave_requests, :status
    add_index :leave_requests, :start_date
    add_foreign_key :leave_requests, :users, column: :reviewed_by
  end
end
