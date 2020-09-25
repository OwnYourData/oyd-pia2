class RenameSchemaIdDri < ActiveRecord::Migration[5.2]
  def change
    rename_column :items, :schema_id, :schema_dri
  end
end
