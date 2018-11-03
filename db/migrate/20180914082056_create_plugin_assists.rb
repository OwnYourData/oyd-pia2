class CreatePluginAssists < ActiveRecord::Migration[5.1]
  def change
    create_table :plugin_assists do |t|
      t.integer :user_id
      t.string :identifier
      t.boolean :assist

      t.timestamps
    end
  end
end
