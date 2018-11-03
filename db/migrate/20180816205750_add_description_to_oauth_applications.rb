class AddDescriptionToOauthApplications < ActiveRecord::Migration[5.1]
  def change
    add_column :oauth_applications, :description, :string
  end
end
