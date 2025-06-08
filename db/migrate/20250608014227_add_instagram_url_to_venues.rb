class AddInstagramUrlToVenues < ActiveRecord::Migration[8.0]
  def change
    add_column :venues, :instagram_url, :string
  end
end
