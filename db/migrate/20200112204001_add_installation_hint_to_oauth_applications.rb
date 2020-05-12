class AddInstallationHintToOauthApplications < ActiveRecord::Migration[5.2]
  def change
    add_column :oauth_applications, :installation_hint, :text
  end
end
