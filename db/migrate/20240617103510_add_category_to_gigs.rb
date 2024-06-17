class AddCategoryToGigs < ActiveRecord::Migration[7.1]
  def change
    add_column :gigs, :category, :string
  end
end
