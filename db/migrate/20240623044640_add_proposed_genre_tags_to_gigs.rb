# frozen_string_literal: true

class AddProposedGenreTagsToGigs < ActiveRecord::Migration[7.1]
  def change
    add_column :gigs, :proposed_genre_tags, :string, array: true
  end
end
