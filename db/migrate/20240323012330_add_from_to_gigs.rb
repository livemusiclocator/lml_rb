class AddFromToGigs < ActiveRecord::Migration[7.1]
  def change
    add_column :gigs, :from, :time
  end
end
