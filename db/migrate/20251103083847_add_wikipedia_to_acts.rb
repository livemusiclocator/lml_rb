class AddWikipediaToActs < ActiveRecord::Migration[8.0]
  def change
    add_column :acts, :wikipedia, :string
  end
end
