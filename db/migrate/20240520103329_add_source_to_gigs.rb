class AddSourceToGigs < ActiveRecord::Migration[7.1]
  def change
    add_column :gigs, :source, :string
  end
end
