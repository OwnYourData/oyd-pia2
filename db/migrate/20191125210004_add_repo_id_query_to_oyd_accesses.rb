class AddRepoIdQueryToOydAccesses < ActiveRecord::Migration[5.2]
  def change
    add_column :oyd_accesses, :repo_id, :integer
    add_column :oyd_accesses, :query_params, :string
  end
end
