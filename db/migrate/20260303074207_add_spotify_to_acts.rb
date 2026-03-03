class AddSpotifyToActs < ActiveRecord::Migration[8.1]
  def change
    add_column :acts, :spotify, :string
  end
end
