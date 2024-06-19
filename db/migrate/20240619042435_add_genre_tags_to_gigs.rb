# frozen_string_literal: true

class AddGenreTagsToGigs < ActiveRecord::Migration[7.1]
  def change
    add_column :gigs, :genre_tags, :string, array: true
  end
end
