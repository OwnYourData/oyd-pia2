class AddPhoneHashToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :phone_hash, :string
  end
end
