class AddVibeToVenues < ActiveRecord::Migration[7.1]
  def change
    add_column :venues, :vibe, :string
  end
end
