# frozen_string_literal: true

# Acts somebody suggested for a gig but nobody has confirmed - the counterpart
# of proposed_genre_tags. A research upload names a gig after the event title
# and leaves the lineup to review, so the lineup it guessed at lands here rather
# than as sets, which would create acts nobody has looked at.
class AddProposedActsToGigs < ActiveRecord::Migration[8.1]
  def change
    add_column :gigs, :proposed_acts, :string, array: true, default: []
  end
end
