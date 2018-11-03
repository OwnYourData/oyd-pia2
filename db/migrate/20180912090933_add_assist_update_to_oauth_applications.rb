class AddAssistUpdateToOauthApplications < ActiveRecord::Migration[5.1]
  def change
    add_column :oauth_applications, :assist_update, :boolean
  end
end
