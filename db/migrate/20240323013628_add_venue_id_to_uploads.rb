class AddVenueIdToUploads < ActiveRecord::Migration[7.1]
  def change
    add_column :uploads, :venue_id, :uuid
  end
end
