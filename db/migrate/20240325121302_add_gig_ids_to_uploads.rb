class AddGigIdsToUploads < ActiveRecord::Migration[7.1]
  def change
    add_column :uploads, :gig_ids, :jsonb
  end
end
