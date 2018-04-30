class CreatePermissions < ActiveRecord::Migration[5.1]
  def change
    create_table :permissions do |t|
      t.integer :plugin_id
      t.string :repo_identifier
      t.integer :perm_type
      t.boolean :perm_allow

      t.timestamps
    end
  end
end
