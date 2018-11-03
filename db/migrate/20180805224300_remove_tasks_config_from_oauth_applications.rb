class RemoveTasksConfigFromOauthApplications < ActiveRecord::Migration[5.1]
  def change
    remove_column :oauth_applications, :tasks
    remove_column :oauth_applications, :config
  end
end
