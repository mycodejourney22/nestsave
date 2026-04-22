class CleanUpOrphanedEmployeeProfilesFromCancelledInvites < ActiveRecord::Migration[7.1]
  def up
    # Soft-delete any EmployeeProfile whose CompanyMembership was already soft-deleted.
    # These were created at invite time but never cleaned up when the invite was cancelled.
    execute <<~SQL
      UPDATE employee_profiles
      SET    deleted_at = NOW()
      WHERE  deleted_at IS NULL
        AND  company_membership_id IN (
               SELECT id FROM company_memberships WHERE deleted_at IS NOT NULL
             )
    SQL
  end

  def down
    # Not reversible — cannot distinguish intentionally kept profiles from orphaned ones.
  end
end
