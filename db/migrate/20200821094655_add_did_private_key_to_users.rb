class AddDidPrivateKeyToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :did_private_key, :string
  end
end
