# frozen_string_literal: true

venue = @venue

json.partial!("shared/venue", venue: venue)

json.upcoming_gigs venue.upcoming_gigs do |gig|
  json.partial!("shared/gig_summary", gig: gig)

  # Who is playing, which is what a venue page is asking. The act page asks the
  # other way round and gets the venue instead - see shared/_gig_summary.
  json.sets(gig.sets.sort_by { |set| set.start_offset || 0 }) do |set|
    json.partial!("shared/set", set: set)
  end
end
