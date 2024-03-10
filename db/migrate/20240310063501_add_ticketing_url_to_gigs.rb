class AddTicketingUrlToGigs < ActiveRecord::Migration[7.1]
  def change
    add_column :gigs, :ticketing_url, :string
  end
end
