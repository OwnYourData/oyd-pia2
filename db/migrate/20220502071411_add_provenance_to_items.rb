class AddProvenanceToItems < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :provenance, :text
  end
end
