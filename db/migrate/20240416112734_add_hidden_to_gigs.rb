class AddHiddenToGigs < ActiveRecord::Migration[7.1]
  def change
    add_column :gigs, :hidden, :boolean
  end
end
