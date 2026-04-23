class AddBellFieldsToNotifications < ActiveRecord::Migration[7.1]
  def change
    add_reference :notifications, :company, type: :uuid, foreign_key: true, null: true
    add_column    :notifications, :title,    :string
    add_column    :notifications, :body,     :string
    add_column    :notifications, :link,     :string
    add_column    :notifications, :category, :string

    # Make notifiable optional so bell-only notifications need no polymorphic target
    change_column_null :notifications, :notifiable_type, true
    change_column_null :notifications, :notifiable_id,   true
    # Allow event to be null for new-style title-based notifications
    change_column_null :notifications, :event, true
  end
end
