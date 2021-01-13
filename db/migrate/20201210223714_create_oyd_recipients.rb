class CreateOydRecipients < ActiveRecord::Migration[5.2]
  def change
    create_table :oyd_recipients do |t|
      t.integer :user_id
      t.integer :source_id
      t.string :recipient_did
      t.string :fragment_identifier
      t.text :fragment_array
      t.integer :key

      t.timestamps
    end
  end
end
