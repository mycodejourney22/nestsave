class CreateNotifications < ActiveRecord::Migration[7.1]
  def change
    create_table :notifications, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid

      t.string :notifiable_type, null: false
      t.uuid   :notifiable_id,   null: false

      t.string  :channel, null: false, default: "email"
      t.string  :event,   null: false

      t.boolean :sent,    null: false, default: false
      t.datetime :sent_at
      t.boolean :read,    null: false, default: false
      t.datetime :read_at

      t.timestamps
    end

    add_index :notifications, [:notifiable_type, :notifiable_id]
    add_index :notifications, [:user_id, :read]
    add_index :notifications, :sent
  end
end
