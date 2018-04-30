class CreateOydViews < ActiveRecord::Migration[5.1]
  def change
    create_table :oyd_views do |t|
      t.integer :plugin_id
      t.integer :plugin_detail_id
      t.string :name
      t.string :identifier
      t.string :url
      t.string :view_type

      t.timestamps
    end
  end
end
