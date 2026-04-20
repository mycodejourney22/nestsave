class CreateTeams < ActiveRecord::Migration[7.1]
  def change
    create_table :teams, id: :uuid do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.string  :name,        null: false
      t.string  :description, null: true
      t.boolean :active,      null: false, default: true
      t.timestamps
      t.datetime :deleted_at
    end

    add_index :teams, [:company_id, :name], unique: true, where: "deleted_at IS NULL"
    add_index :teams, :deleted_at
  end
end
