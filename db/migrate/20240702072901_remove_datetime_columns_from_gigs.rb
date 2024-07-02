# frozen_string_literal: true

class RemoveDatetimeColumnsFromGigs < ActiveRecord::Migration[7.1]
  def change
    remove_column :gigs, :start_time
    remove_column :gigs, :finish_time
  end
end
