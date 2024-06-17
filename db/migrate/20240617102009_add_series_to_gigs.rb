class AddSeriesToGigs < ActiveRecord::Migration[7.1]
  def change
    add_column :gigs, :series, :string
  end
end
