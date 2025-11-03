class AddMusicbrainzToActs < ActiveRecord::Migration[8.0]
  def change
    add_column :acts, :musicbrainz, :string
  end
end
