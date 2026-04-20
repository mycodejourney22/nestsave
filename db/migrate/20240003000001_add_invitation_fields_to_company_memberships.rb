class AddInvitationFieldsToCompanyMemberships < ActiveRecord::Migration[7.1]
  def up
    change_column_null :company_memberships, :user_id, true

    add_column :company_memberships, :invited_name,           :string
    add_column :company_memberships, :invited_email,          :string
    add_column :company_memberships, :invitation_token,       :string
    add_column :company_memberships, :invitation_sent_at,     :datetime
    add_column :company_memberships, :invitation_accepted_at, :datetime

    add_index :company_memberships, :invitation_token, unique: true, where: "invitation_token IS NOT NULL"
    add_index :company_memberships, :invited_email
  end

  def down
    remove_index :company_memberships, :invited_email
    remove_index :company_memberships, :invitation_token

    remove_column :company_memberships, :invitation_accepted_at
    remove_column :company_memberships, :invitation_sent_at
    remove_column :company_memberships, :invitation_token
    remove_column :company_memberships, :invited_email
    remove_column :company_memberships, :invited_name

    change_column_null :company_memberships, :user_id, false
  end
end
