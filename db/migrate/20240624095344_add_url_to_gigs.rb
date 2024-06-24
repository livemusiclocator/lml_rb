class AddUrlToGigs < ActiveRecord::Migration[7.1]
  def change
    add_column :gigs, :url, :string
  end
end
