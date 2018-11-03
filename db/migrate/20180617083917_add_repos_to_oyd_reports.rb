class AddReposToOydReports < ActiveRecord::Migration[5.1]
  def change
    add_column :oyd_reports, :repos, :text
  end
end
