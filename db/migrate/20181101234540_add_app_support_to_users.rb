class AddAppSupportToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :app_nonce, :string
    add_column :users, :app_cipher, :string
  end
end
