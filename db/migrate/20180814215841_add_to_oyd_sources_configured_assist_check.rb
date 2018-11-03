class AddToOydSourcesConfiguredAssistCheck < ActiveRecord::Migration[5.1]
  def change
    add_column :oyd_sources, :configured, :boolean
    add_column :oyd_sources, :assist_check, :boolean
  end
end
