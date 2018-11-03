class AddInactiveDurationInactiveTextToOydSources < ActiveRecord::Migration[5.1]
  def change
    add_column :oyd_sources, :inactive_duration, :integer
    add_column :oyd_sources, :inactive_text, :string
  end
end
