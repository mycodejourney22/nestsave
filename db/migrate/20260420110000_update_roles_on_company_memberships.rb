class UpdateRolesOnCompanyMemberships < ActiveRecord::Migration[7.1]
  def up
    execute <<-SQL
      UPDATE company_memberships
      SET role = 'hr_admin'
      WHERE role = 'payroll_admin'
    SQL
  end

  def down
    execute <<-SQL
      UPDATE company_memberships
      SET role = 'payroll_admin'
      WHERE role = 'hr_admin'
    SQL
  end
end
