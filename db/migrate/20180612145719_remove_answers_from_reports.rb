class RemoveAnswersFromReports < ActiveRecord::Migration[5.1]
  def change
    remove_column :oyd_reports, :answer_view
    remove_column :oyd_reports, :answer_logic
  end
end
