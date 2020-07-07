class AddPhoneKeyToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :phone_key, :string
  end
end
