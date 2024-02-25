class AddVenueToEvents < ActiveRecord::Migration[7.1]
  def change
    add_reference :events, :venue, foreign_key: true
  end
end
