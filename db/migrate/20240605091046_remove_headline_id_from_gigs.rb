class RemoveHeadlineIdFromGigs < ActiveRecord::Migration[7.1]
  def change
    remove_column :gigs, :headline_act_id
  end
end
