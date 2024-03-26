class AddCapacityToVenues < ActiveRecord::Migration[7.1]
  def change
    add_column :venues, :capacity, :integer
  end
end
