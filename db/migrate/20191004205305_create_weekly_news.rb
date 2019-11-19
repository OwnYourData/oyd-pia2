class CreateWeeklyNews < ActiveRecord::Migration[5.2]
  def change
    create_table :weekly_news do |t|
      t.string :week
      t.text :news_text

      t.timestamps
    end
  end
end
