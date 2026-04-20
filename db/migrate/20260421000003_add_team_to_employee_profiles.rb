class AddTeamToEmployeeProfiles < ActiveRecord::Migration[7.1]
  def change
    add_column :employee_profiles, :team_id, :uuid, null: true
    add_foreign_key :employee_profiles, :teams, column: :team_id
    add_index :employee_profiles, :team_id
  end
end
