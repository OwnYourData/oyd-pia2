class AddPasswordKeysToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :password_key, :string
    add_column :users, :recovery_password_key, :string
  end
end
