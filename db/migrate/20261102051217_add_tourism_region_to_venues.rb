class AddTourismRegionToVenues < ActiveRecord::Migration[8.1]
  def change
    add_reference :venues, :tourism_region, foreign_key: true, type: :uuid
  end
end
