class AddUploadIdToGigs < ActiveRecord::Migration[7.1]
  def change
    add_column :gigs, :upload_id, :uuid
  end
end
