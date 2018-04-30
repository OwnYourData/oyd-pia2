class RemoveUserIdFromDoorkeeperApps < ActiveRecord::Migration[5.1]
  def change
  		remove_column :oauth_applications, :user_id
  end
end
