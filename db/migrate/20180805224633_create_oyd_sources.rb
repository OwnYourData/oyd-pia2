class CreateOydSources < ActiveRecord::Migration[5.1]
  def change
    create_table :oyd_sources do |t|
      t.integer :plugin_id
      t.string :name
      t.string :description
      t.string :type
      t.text :config
      t.text :config_values

      t.timestamps
    end
  end
end
