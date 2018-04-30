class AddRecoveryPasswordToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :recovery_password_digest, :string
  end
end
