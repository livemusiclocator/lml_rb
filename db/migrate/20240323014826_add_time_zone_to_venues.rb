class AddTimeZoneToVenues < ActiveRecord::Migration[7.1]
  def change
    add_column :venues, :time_zone, :string
  end
end
