class AddSowluserToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :sowl_user, :string
  end
end
