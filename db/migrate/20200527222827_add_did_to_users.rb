class AddDidToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :did, :string
  end
end
