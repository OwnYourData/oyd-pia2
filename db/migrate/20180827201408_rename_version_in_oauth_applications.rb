class RenameVersionInOauthApplications < ActiveRecord::Migration[5.1]
  def change
    rename_column :oauth_applications, :version, :oyd_version
  end
end
