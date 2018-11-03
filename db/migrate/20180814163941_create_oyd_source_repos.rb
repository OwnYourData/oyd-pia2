class CreateOydSourceRepos < ActiveRecord::Migration[5.1]
  def change
    create_table :oyd_source_repos do |t|
      t.integer :oyd_source_id
      t.integer :repo_id
      t.boolean :assist_check

      t.timestamps
    end
  end
end
