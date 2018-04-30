class RenameTransactionInMerkles < ActiveRecord::Migration[5.1]
  def change
    rename_column :merkles, :transaction, :oyd_transaction
  end
end
