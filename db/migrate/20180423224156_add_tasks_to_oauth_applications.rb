class AddTasksToOauthApplications < ActiveRecord::Migration[5.1]
  def change
    add_column :oauth_applications, :tasks, :text
  end
end
