class CreateRepos < ActiveRecord::Migration[5.1]
  def change
    create_table :repos do |t|
      t.integer :user_id
      t.string :name
      t.string :identifier
      t.string :public_key

      t.timestamps
    end
  end
end
