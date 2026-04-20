class CreateEmergencyContacts < ActiveRecord::Migration[7.1]
  def change
    create_table :emergency_contacts, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :employee_profile, type: :uuid, null: false, foreign_key: true
      t.string  :full_name,    null: false
      t.string  :relationship, null: false
      t.string  :phone,        null: false
      t.string  :email
      t.boolean :primary,      default: false, null: false

      t.timestamps
    end
  end
end
