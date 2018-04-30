class CreateOydReportTemplates < ActiveRecord::Migration[5.1]
  def change
    create_table :oyd_report_templates do |t|
      t.integer :plugin_id
      t.string :identifier
      t.text :data_prep
      t.text :data_view

      t.timestamps
    end
  end
end
