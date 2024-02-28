class AddVenueToGigs < ActiveRecord::Migration[7.1]
  def change
    add_reference :gigs, :venue, type: :uuid, foreign_key: true
  end
end
