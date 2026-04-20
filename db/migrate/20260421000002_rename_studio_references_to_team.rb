class RenameStudioReferencesToTeam < ActiveRecord::Migration[7.1]
  def up
    add_column :company_memberships, :team_id, :uuid, null: true
    add_foreign_key :company_memberships, :teams, column: :team_id
    add_index :company_memberships, :team_id

    execute "UPDATE company_memberships SET role = 'team_manager' WHERE role = 'studio_manager'"
  end

  def down
    execute "UPDATE company_memberships SET role = 'studio_manager' WHERE role = 'team_manager'"
    remove_foreign_key :company_memberships, column: :team_id
    remove_index :company_memberships, :team_id
    remove_column :company_memberships, :team_id
  end
end
