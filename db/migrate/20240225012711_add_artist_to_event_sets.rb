class AddArtistToEventSets < ActiveRecord::Migration[7.1]
  def change
    add_reference :event_sets, :artist, foreign_key: true
  end
end
