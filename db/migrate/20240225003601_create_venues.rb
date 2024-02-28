class CreateVenues < ActiveRecord::Migration[7.1]
  def change
    create_table :venues, id: :uuid do |t|
      t.string :name
      t.string :address
      t.string :location_url
      t.float :latitude
      t.float :longitude

      t.timestamps
    end
  end
end
