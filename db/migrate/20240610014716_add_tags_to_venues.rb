class AddTagsToVenues < ActiveRecord::Migration[7.1]
  def change
    add_column :venues, :tags, :jsonb
  end
end
