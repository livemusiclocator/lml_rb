class AddStatusToGigs < ActiveRecord::Migration[7.1]
  def change
    add_reference :gigs, :status, type: :uuid, foreign_key: true
  end
end
