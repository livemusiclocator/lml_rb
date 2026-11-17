# frozen_string_literal: true

# The gig ids each entry of an upload became, in entry order, so the upload can
# hand its content back with an id on every entry - see Upload#content_with_ids.
class AddEntryGigIdsToUploads < ActiveRecord::Migration[8.1]
  def change
    add_column :uploads, :entry_gig_ids, :jsonb, default: [], null: false
  end
end
