class AddStartOffsetToGigs < ActiveRecord::Migration[7.1]
  def change
    add_column :gigs, :start_offset, :integer
  end
end
