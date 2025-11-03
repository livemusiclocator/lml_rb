class AddBandcampToActs < ActiveRecord::Migration[8.0]
  def change
    add_column :acts, :bandcamp, :string
  end
end
