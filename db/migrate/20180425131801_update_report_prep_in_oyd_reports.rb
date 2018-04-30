class UpdateReportPrepInOydReports < ActiveRecord::Migration[5.1]
  def change
    rename_column :oyd_reports, :report_gen, :data_prep
  end
end
