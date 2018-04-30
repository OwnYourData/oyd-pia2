class CreateLogs < ActiveRecord::Migration[5.1]
  def change
    create_table :logs do |t|
      t.integer :user_id
      t.integer :plugin_id
      t.string :identifier
      t.text :message

      t.timestamps
    end
  end
end
