class AddDescriptionToGigs < ActiveRecord::Migration[7.1]
  def change
    add_column :gigs, :description, :text
  end
end
