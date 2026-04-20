class RemoveSalaryFromCompanyMemberships < ActiveRecord::Migration[7.1]
  def up
    remove_column :company_memberships, :salary
  end

  def down
    add_column :company_memberships, :salary, :decimal, precision: 12, scale: 2, null: true
  end
end
