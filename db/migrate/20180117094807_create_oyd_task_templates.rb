class CreateOydTaskTemplates < ActiveRecord::Migration[5.1]
  def change
    create_table :oyd_task_templates do |t|
      t.integer :plugin_id
      t.string :identifier
      t.text :command
      t.string :schedule

      t.timestamps
    end
  end
end
