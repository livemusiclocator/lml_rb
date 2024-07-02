# frozen_string_literal: true

class RemoveGigIdsColumnFromUploads < ActiveRecord::Migration[7.1]
  def change
    remove_column :uploads, :gig_ids
  end
end
