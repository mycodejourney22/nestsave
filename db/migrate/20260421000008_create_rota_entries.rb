class CreateRotaEntries < ActiveRecord::Migration[7.1]
  def change
    create_table :rota_entries, id: :uuid do |t|
      t.references :rota,             null: false, type: :uuid, foreign_key: { to_table: :rotas }
      t.references :employee_profile, null: false, type: :uuid, foreign_key: true
      t.date   :work_date,  null: false
      t.time   :start_time, null: true
      t.time   :end_time,   null: true
      t.string :notes,      null: true
      t.timestamps
    end

    add_index :rota_entries, [:rota_id, :employee_profile_id, :work_date],
              unique: true, name: "idx_rota_entries_unique"
  end
end
