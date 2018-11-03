class AddStatsToOydSourceRepos < ActiveRecord::Migration[5.1]
  def change
    add_column :oyd_source_repos, :stats, :boolean
  end
end
