class RemoveStatusIdFromGigs < ActiveRecord::Migration[7.1]
  def change
    remove_column :gigs, :status_id, :uuid
  end
end
