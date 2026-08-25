# frozen_string_literal: true

act = @act

json.partial!("shared/act", act: act)

json.upcoming_gigs act.upcoming_gigs do |gig|
  json.partial!("shared/gig_summary", gig: gig)

  venue = gig.venue
  json.venue { json.partial!("shared/venue", venue: venue) } if venue
end
