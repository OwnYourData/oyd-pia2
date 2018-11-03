class AddOydSourcePileIdToItems < ActiveRecord::Migration[5.1]
  def change
    add_column :items, :oyd_source_pile_id, :integer
  end
end
