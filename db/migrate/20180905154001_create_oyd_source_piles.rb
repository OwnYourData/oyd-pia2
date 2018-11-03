class CreateOydSourcePiles < ActiveRecord::Migration[5.1]
  def change
    create_table :oyd_source_piles do |t|
      t.integer :oyd_source_id
      t.text :content
      t.string :email
      t.text :signature
      t.text :verification

      t.timestamps
    end
  end
end
