class AddLeavingReasonToCompanyMemberships < ActiveRecord::Migration[7.1]
  def change
    add_column :company_memberships, :leaving_reason, :string
  end
end
