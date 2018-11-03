class AddVersionToOauthApplications < ActiveRecord::Migration[5.1]
  def change
    add_column :oauth_applications, :version, :string
  end
end
