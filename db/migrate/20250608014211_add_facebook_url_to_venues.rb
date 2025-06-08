class AddFacebookUrlToVenues < ActiveRecord::Migration[8.0]
  def change
    add_column :venues, :facebook_url, :string
  end
end
