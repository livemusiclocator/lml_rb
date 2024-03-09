class AddLocationToVenues < ActiveRecord::Migration[7.1]
  def change
    add_column :venues, :location, :string
  end
end
