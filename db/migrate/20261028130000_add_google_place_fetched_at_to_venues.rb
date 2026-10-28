# frozen_string_literal: true

# When google_place was last fetched, so backstage can say how fresh it is.
# Every venue that has one got it from today's backfill, or from a lookup since,
# so updated_at is a fair starting value for them.
class AddGooglePlaceFetchedAtToVenues < ActiveRecord::Migration[8.1]
  def up
    add_column :venues, :google_place_fetched_at, :datetime
    execute "UPDATE venues SET google_place_fetched_at = updated_at WHERE google_place IS NOT NULL"
  end

  def down
    remove_column :venues, :google_place_fetched_at
  end
end
