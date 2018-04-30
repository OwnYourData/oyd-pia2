class AddCommentToBackups < ActiveRecord::Migration[5.1]
  def change
    add_column :backups, :comment, :string
  end
end
