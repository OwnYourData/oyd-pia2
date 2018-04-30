class AddNameInfoUrlToOydReports < ActiveRecord::Migration[5.1]
  def change
    add_column :oyd_reports, :name, :string
    add_column :oyd_reports, :info_url, :string
  end
end
