class AddConfidentialToDoorkeeper < ActiveRecord::Migration[5.2]
  def change
    add_column :oauth_applications, :confidential, :boolean, default: true, null: false
  end
end
