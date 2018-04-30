class AddCurrentToOydReports < ActiveRecord::Migration[5.1]
  def change
    add_column :oyd_reports, :current, :text
  end
end
