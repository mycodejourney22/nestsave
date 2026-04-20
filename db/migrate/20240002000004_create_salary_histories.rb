class CreateSalaryHistories < ActiveRecord::Migration[7.1]
  def change
    create_table :salary_histories, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :employee_profile, type: :uuid, null: false, foreign_key: true
      t.decimal :amount,         precision: 12, scale: 2, null: false
      t.string  :currency,       default: "GBP", null: false
      t.string  :reason
      t.date    :effective_date, null: false
      t.uuid    :changed_by,     null: false
      t.text    :notes

      t.datetime :created_at, null: false
    end

    add_foreign_key :salary_histories, :users, column: :changed_by
    add_index :salary_histories, :effective_date
  end
end
