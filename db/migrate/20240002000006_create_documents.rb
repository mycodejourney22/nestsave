class CreateDocuments < ActiveRecord::Migration[7.1]
  def change
    create_table :documents, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :employee_profile, type: :uuid, null: false, foreign_key: true
      t.string  :title,       null: false
      t.string  :category,    null: false, default: "other"
      t.string  :file_path,   null: false
      t.string  :file_name,   null: false
      t.string  :mime_type
      t.integer :file_size_kb
      t.text    :notes
      t.uuid    :uploaded_by, null: false
      t.datetime :deleted_at

      t.datetime :created_at, null: false
    end

    add_foreign_key :documents, :users, column: :uploaded_by
    add_index :documents, :deleted_at
  end
end
