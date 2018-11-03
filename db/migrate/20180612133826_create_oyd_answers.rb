class CreateOydAnswers < ActiveRecord::Migration[5.1]
  def change
    create_table :oyd_answers do |t|
      t.integer :plugin_id
      t.string :name
      t.string :identifier
      t.string :category
      t.string :info_url
      t.text :repos
      t.integer :answer_order
      t.text :answer_view
      t.text :answer_logic

      t.timestamps
    end
  end
end
