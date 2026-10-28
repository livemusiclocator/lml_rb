# frozen_string_literal: true

# Who sent an upload: the backstage user whose API token posted it. It is what
# lets the review queue start from "your uploads" rather than every unchecked
# gig LML holds. Older uploads, and the ones ActiveAdmin makes, have none.
class AddUserToUploads < ActiveRecord::Migration[8.1]
  def change
    add_reference :uploads, :user, type: :uuid, foreign_key: true, null: true
  end
end
