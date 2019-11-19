class CreateOydAccesses < ActiveRecord::Migration[5.2]
  def change
    create_table :oyd_accesses do |t|
      t.integer :timestamp
      t.integer :operation
      t.string :oyd_hash
      t.integer :merkle_id
      t.integer :plugin_id
      t.integer :item_id
      t.integer :user_id
      t.integer :previous_id

      t.timestamps
    end
  end
end
