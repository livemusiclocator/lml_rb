class AddTagsToGigs < ActiveRecord::Migration[7.1]
  def change
    add_column :gigs, :tags, :jsonb
  end
end
