class AddEmailNotifToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :email_notif, :boolean
  end
end
