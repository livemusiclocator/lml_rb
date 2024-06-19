# frozen_string_literal: true

class AddInformationTagsToGigs < ActiveRecord::Migration[7.1]
  def change
    add_column :gigs, :information_tags, :string, array: true
  end
end
