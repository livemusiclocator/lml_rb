# frozen_string_literal: true

# Who last sent a gig in. The review queue's "mine" and the dashboard used to
# find this through gigs.upload_id and the upload's user, but the admin API's
# bulk update keeps no upload, so the user goes on the gig itself. Filled in
# from the uploads that already say who sent them.
class AddUploadedByToGigs < ActiveRecord::Migration[8.1]
  def up
    add_reference :gigs, :uploaded_by, type: :uuid, foreign_key: { to_table: :users }, null: true
    execute <<~SQL.squish
      UPDATE gigs SET uploaded_by_id = uploads.user_id
      FROM uploads
      WHERE gigs.upload_id = uploads.id AND uploads.user_id IS NOT NULL
    SQL
  end

  def down
    remove_reference :gigs, :uploaded_by
  end
end
