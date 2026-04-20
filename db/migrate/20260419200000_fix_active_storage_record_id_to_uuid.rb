class FixActiveStorageRecordIdToUuid < ActiveRecord::Migration[7.1]
  def up
    remove_index :active_storage_attachments,
      name: "index_active_storage_attachments_uniqueness" rescue nil

    remove_column :active_storage_attachments, :record_id

    add_column :active_storage_attachments, :record_id, :uuid, null: false

    add_index :active_storage_attachments,
      [:record_type, :record_id, :name, :blob_id],
      name: "index_active_storage_attachments_uniqueness",
      unique: true
  end

  def down
    remove_index :active_storage_attachments,
      name: "index_active_storage_attachments_uniqueness" rescue nil

    remove_column :active_storage_attachments, :record_id

    add_column :active_storage_attachments, :record_id, :bigint, null: false

    add_index :active_storage_attachments,
      [:record_type, :record_id, :name, :blob_id],
      name: "index_active_storage_attachments_uniqueness",
      unique: true
  end
end
