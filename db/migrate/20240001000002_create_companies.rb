class CreateCompanies < ActiveRecord::Migration[7.1]
  def change
    create_table :companies, id: :uuid do |t|
      t.string  :name,          null: false
      t.string  :slug,          null: false
      t.string  :payroll_email, null: false
      t.string  :timezone,      null: false, default: "UTC"
      t.integer :payroll_day,   null: false, default: 25
      t.boolean :active,        null: false, default: true

      t.timestamps
      t.datetime :deleted_at
    end

    add_index :companies, :slug,       unique: true
    add_index :companies, :deleted_at
  end
end
