class AddAddressComponentsToVenues < ActiveRecord::Migration[8.1]
  def change
    add_column :venues, :address_components, :jsonb, default: {}, null: false
    add_column :venues, :google_place_id, :string

    add_index :venues, :address_components, using: :gin
    add_index :venues, :google_place_id
  end
end
