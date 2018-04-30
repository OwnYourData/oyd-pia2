class CreateItems < ActiveRecord::Migration[5.1]
  def change
    create_table :items do |t|
      t.integer :repo_id
      t.integer :merkle_id
      t.text :value
      t.string :hash

      t.timestamps
    end
  end
end
