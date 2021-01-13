class AddEidasTokenToItems < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :eidas_token, :string
  end
end
