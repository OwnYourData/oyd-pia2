class CreateOydInstalls < ActiveRecord::Migration[5.2]
  def change
    create_table :oyd_installs do |t|
      t.integer :plugin_id
      t.string :code
      t.timestamp :requested_ts

      t.timestamps
    end
  end
end
