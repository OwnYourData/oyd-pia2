class CreateOydTasks < ActiveRecord::Migration[5.1]
  def change
    create_table :oyd_tasks do |t|
      t.integer :plugin_id
      t.string :identifier
      t.text :command
      t.string :schedule
      t.datetime :next_run

      t.timestamps
    end
  end
end
