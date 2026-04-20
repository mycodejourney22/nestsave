class CreateDepartments < ActiveRecord::Migration[7.1]
  def change
    create_table :departments, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.string  :name,     null: false
      t.string  :color,    default: "#1D9E75"
      t.boolean :active,   default: true, null: false
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :departments, [:company_id, :name], unique: true, where: "deleted_at IS NULL"
    add_index :departments, :deleted_at
  end
end
