class RemoveAssistCheckFromOydSourceRepos < ActiveRecord::Migration[5.1]
  def change
    remove_column :oyd_source_repos, :assist_check
  end
end
