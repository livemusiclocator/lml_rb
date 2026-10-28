# frozen_string_literal: true

# The ids of venues merged into this one, so a link to a venue that no longer
# exists can still find where it went.
class AddMergedVenueIdsToVenues < ActiveRecord::Migration[8.1]
  def change
    add_column :venues, :merged_venue_ids, :uuid, array: true, default: [], null: false
  end
end
