class RemoveFileColumnsFromDocuments < ActiveRecord::Migration[7.1]
  def up
    remove_column :documents, :file_path,    :string
    remove_column :documents, :file_name,    :string
    remove_column :documents, :mime_type,    :string
    remove_column :documents, :file_size_kb, :integer
  end

  def down
    add_column :documents, :file_path,    :string, null: false, default: ""
    add_column :documents, :file_name,    :string, null: false, default: ""
    add_column :documents, :mime_type,    :string
    add_column :documents, :file_size_kb, :integer
  end
end
