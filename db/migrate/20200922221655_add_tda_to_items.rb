class AddTdaToItems < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :dri, :string
    add_column :items, :schema_id, :string
    add_column :items, :mime_type, :string
    add_index :items, :dri
    add_index :items, :schema_id
  end
end
