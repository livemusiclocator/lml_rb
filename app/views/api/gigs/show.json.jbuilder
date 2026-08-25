# frozen_string_literal: true

gig = @gig

json.id gig.id
json.name gig.name
json.date gig.date
json.ticketing_url gig.ticketing_url
json.start_time gig.start_time
json.start_timestamp gig.start_timestamp
json.duration gig.duration
json.finish_time gig.finish_time
json.finish_timestamp gig.finish_timestamp
json.description gig.description
json.status gig.status
json.ticket_status gig.ticket_status
json.series gig.series
json.category gig.category
json.information_tags gig.information_tags || []
json.genre_tags gig.genre_tags || []

venue = gig.venue
json.venue { json.partial!("shared/venue", venue: venue) } if venue

json.sets gig.sets.order(:start_offset) do |set|
  json.start_time set.start_time
  json.start_timestamp set.start_timestamp
  json.duration set.duration
  json.finish_time set.finish_time
  json.finish_timestamp set.finish_timestamp

  json.act { json.partial!("shared/act", act: set.act) }
end

json.prices gig.prices do |price|
  json.amount price.amount.format if price.amount
  json.description price.description if price.description
end
