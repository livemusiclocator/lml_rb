class AddPostcodeToVenues < ActiveRecord::Migration[7.1]
  def change
    add_column :venues, :postcode, :string
  end
end
