# frozen_string_literal: true

act = @act

json.partial!("shared/act", act: act)

json.upcoming_gigs act.upcoming_gigs do |gig|
  json.id gig.id
  json.name gig.name
  json.date gig.date
  json.start_time gig.start_time
  json.start_timestamp gig.start_timestamp
  json.ticketing_url gig.ticketing_url
  json.status gig.status
  json.ticket_status gig.ticket_status

  venue = gig.venue
  json.venue { json.partial!("shared/venue", venue: venue) } if venue
end
