# frozen_string_literal: true

# A gig as it appears in a list on someone else's page - an act's upcoming gigs,
# a venue's. Just the gig's own fields: each caller adds the part its page is
# actually asking about, which is the venue for an act and the sets for a venue.

json.id gig.id
json.name gig.name
json.date gig.date
json.start_time gig.start_time
json.start_timestamp gig.start_timestamp
json.ticketing_url gig.ticketing_url
json.status gig.status
json.ticket_status gig.ticket_status
