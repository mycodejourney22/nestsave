class CreateBankDetails < ActiveRecord::Migration[7.1]
  def change
    create_table :bank_details, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :employee_profile, type: :uuid, null: false, foreign_key: true
      t.string  :bank_name,      null: false
      t.string  :account_name,   null: false
      t.string  :account_number, null: false
      t.string  :sort_code,      null: false
      t.boolean :active,         default: true, null: false
      t.uuid    :recorded_by,    null: false

      t.datetime :created_at, null: false
    end

    add_foreign_key :bank_details, :users, column: :recorded_by
    add_index :bank_details, [:employee_profile_id, :active]
  end
end
