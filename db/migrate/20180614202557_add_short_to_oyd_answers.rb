class AddShortToOydAnswers < ActiveRecord::Migration[5.1]
  def change
    add_column :oyd_answers, :short, :string
  end
end
