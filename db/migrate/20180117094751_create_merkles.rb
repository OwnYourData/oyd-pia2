class CreateMerkles < ActiveRecord::Migration[5.1]
  def change
    create_table :merkles do |t|
      t.text :payload
      t.string :root_hash
      t.string :transaction

      t.timestamps
    end
  end
end
