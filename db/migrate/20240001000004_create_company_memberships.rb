class CreateCompanyMemberships < ActiveRecord::Migration[7.1]
  def change
    create_table :company_memberships, id: :uuid do |t|
      t.references :user,    null: false, foreign_key: true, type: :uuid
      t.references :company, null: false, foreign_key: true, type: :uuid

      t.string  :role,       null: false, default: "employee"
      t.decimal :salary,     precision: 12, scale: 2, null: false
      t.string  :status,     null: false, default: "active"

      t.uuid    :invited_by
      t.datetime :joined_at

      t.timestamps
      t.datetime :deleted_at
    end

    add_index :company_memberships, [:user_id, :company_id], unique: true, where: "deleted_at IS NULL"
    add_index :company_memberships, :role
    add_index :company_memberships, :status
    add_index :company_memberships, :deleted_at

    add_foreign_key :company_memberships, :users, column: :invited_by
  end
end
