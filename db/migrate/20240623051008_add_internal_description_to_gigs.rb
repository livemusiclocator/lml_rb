class AddInternalDescriptionToGigs < ActiveRecord::Migration[7.1]
  def change
    add_column :gigs, :internal_description, :text
  end
end
