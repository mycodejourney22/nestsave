class AddManagerApprovalToLeaveRequests < ActiveRecord::Migration[7.1]
  def change
    add_column :leave_requests, :manager_reviewed_by, :uuid, null: true
    add_column :leave_requests, :manager_reviewed_at, :datetime, null: true
    add_foreign_key :leave_requests, :users, column: :manager_reviewed_by
  end
end
