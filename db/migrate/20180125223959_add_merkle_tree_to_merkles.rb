class AddMerkleTreeToMerkles < ActiveRecord::Migration[5.1]
  def change
    add_column :merkles, :merkle_tree, :text
  end
end
