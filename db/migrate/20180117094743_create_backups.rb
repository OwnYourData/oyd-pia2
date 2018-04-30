class CreateBackups < ActiveRecord::Migration[5.1]
  def change
    create_table :backups do |t|
      t.integer :user_id
      t.string :location

      t.timestamps
    end
  end
end
