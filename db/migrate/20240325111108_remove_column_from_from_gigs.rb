class RemoveColumnFromFromGigs < ActiveRecord::Migration[7.1]
  def change
    remove_column :gigs, :from
  end
end
