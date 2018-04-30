class CreatePluginDetails < ActiveRecord::Migration[5.1]
  def change
    create_table :plugin_details do |t|
      t.string :description
      t.string :info_url
      t.text :picture

      t.timestamps
    end
  end
end
