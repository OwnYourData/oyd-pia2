class AddIdentifierToOydSources < ActiveRecord::Migration[5.1]
  def change
    add_column :oyd_sources, :identifier, :string
    rename_column :oyd_sources, :type, :source_type
  end
end
