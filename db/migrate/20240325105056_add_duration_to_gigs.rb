class AddDurationToGigs < ActiveRecord::Migration[7.1]
  def change
    add_column :gigs, :duration, :integer
  end
end
