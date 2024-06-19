# frozen_string_literal: true

class RemoveTagsColumnFromGigs < ActiveRecord::Migration[7.1]
  def change
    remove_column :gigs, :tags
  end
end
