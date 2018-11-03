class AddPermsToOauthApplications < ActiveRecord::Migration[5.1]
  def change
    add_column :oauth_applications, :perms, :text
  end
end
