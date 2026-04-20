class CreateRotas < ActiveRecord::Migration[7.1]
  def change
    create_table :rotas, id: :uuid do |t|
      t.references :team, null: false, foreign_key: true, type: :uuid
      t.uuid    :created_by,   null: false
      t.date    :week_start,   null: false
      t.date    :week_end,     null: false
      t.string  :status,       null: false, default: "draft"
      t.datetime :published_at, null: true
      t.timestamps
    end

    add_index :rotas, [:team_id, :week_start], unique: true
    add_foreign_key :rotas, :users, column: :created_by
  end
end
