class AddAssistRelaxToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :assist_relax, :boolean
  end
end
