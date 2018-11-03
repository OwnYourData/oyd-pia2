class AddReportOrderToOydReports < ActiveRecord::Migration[5.1]
  def change
    add_column :oyd_reports, :report_order, :integer
  end
end
