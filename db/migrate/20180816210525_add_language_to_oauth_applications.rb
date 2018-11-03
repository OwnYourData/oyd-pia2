class AddLanguageToOauthApplications < ActiveRecord::Migration[5.1]
  def change
    add_column :oauth_applications, :language, :string
  end
end
