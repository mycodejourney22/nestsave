class AddDepartmentIdToEmployeeProfiles < ActiveRecord::Migration[7.1]
  def change
    add_reference :employee_profiles, :department, null: true, foreign_key: true, type: :uuid
  end
end
