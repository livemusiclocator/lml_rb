class AddHeadlineArtistToEvents < ActiveRecord::Migration[7.1]
  def change
    add_reference :events, :headline_artist, foreign_key: { to_table: :artists }
  end
end
