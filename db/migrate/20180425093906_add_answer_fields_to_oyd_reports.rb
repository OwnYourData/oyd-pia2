class AddAnswerFieldsToOydReports < ActiveRecord::Migration[5.1]
  def change
    rename_column :oyd_reports, :data_view, :report_view
    rename_column :oyd_reports, :data_prep, :report_gen
    add_column :oyd_reports, :data_snippet, :text
    add_column :oyd_reports, :answer_view, :text
    add_column :oyd_reports, :answer_logic, :text
  end
end
