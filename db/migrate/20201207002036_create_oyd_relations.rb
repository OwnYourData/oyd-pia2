class CreateOydRelations < ActiveRecord::Migration[5.2]
  def change
    create_table :oyd_relations do |t|
      t.integer :source_id
      t.integer :target_id

      t.timestamps
    end
    add_index :oyd_relations, :source_id
    add_index :oyd_relations, :target_id
  end
end
