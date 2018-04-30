class RenameHashToOydHash < ActiveRecord::Migration[5.1]
  def change
	rename_column :items, :hash, :oyd_hash
  end
end
