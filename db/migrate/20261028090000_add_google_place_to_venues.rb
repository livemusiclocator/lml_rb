# frozen_string_literal: true

# The whole Place Details response for a venue picked from Google Places, so
# nothing Google told us is thrown away - address_components keeps only the
# parts an address is matched on.
class AddGooglePlaceToVenues < ActiveRecord::Migration[8.1]
  def change
    add_column :venues, :google_place, :jsonb
  end
end
