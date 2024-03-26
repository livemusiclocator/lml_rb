class AddWebsiteToVenues < ActiveRecord::Migration[7.1]
  def change
    add_column :venues, :website, :string
  end
end
