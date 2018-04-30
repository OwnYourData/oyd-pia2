class AddConfigToOauthApplications < ActiveRecord::Migration[5.1]
  def change
    add_column :oauth_applications, :config, :text
  end
end
