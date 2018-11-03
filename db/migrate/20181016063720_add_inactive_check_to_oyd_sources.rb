class AddInactiveCheckToOydSources < ActiveRecord::Migration[5.1]
  def change
    add_column :oyd_sources, :inactive_check, :boolean
  end
end
