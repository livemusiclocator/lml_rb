class AddCheckedToGigs < ActiveRecord::Migration[7.1]
  def change
    add_column :gigs, :checked, :boolean
  end
end
