class AddGoogleBusinessStatusToVenues < ActiveRecord::Migration[8.1]
  def change
    add_column :venues, :google_business_status, :string
    add_index :venues, :google_business_status
  end
end
