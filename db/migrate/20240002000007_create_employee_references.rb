class CreateEmployeeReferences < ActiveRecord::Migration[7.1]
  def change
    create_table :employee_references, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :employee_profile, type: :uuid, null: false, foreign_key: true
      t.string :referee_name,  null: false
      t.string :organisation
      t.string :relationship,  null: false
      t.string :email
      t.string :phone
      t.string :status,        null: false, default: "not_requested"
      t.date   :requested_on
      t.date   :received_on
      t.text   :notes

      t.timestamps
    end

    add_index :employee_references, :status
  end
end
