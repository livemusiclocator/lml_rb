gig = @gig

json.id gig.id
json.name gig.name
json.date gig.date
json.tags gig.tags || []
json.ticketing_url gig.ticketing_url
json.start_offset_time gig.start_offset_time
json.start_time gig.start_at
json.duration gig.duration
json.finish_time gig.finish_time
json.description gig.description
json.status gig.status
json.series gig.series
json.category gig.category
json.information_tags gig.information_tags
json.genre_tags gig.genre_tags

venue = gig.venue
if venue
  json.venue do
    json.id venue.id
    json.name venue.name
    json.address venue.address
    json.capacity venue.capacity
    json.website venue.website
    json.location_url venue.location_url
    json.latitude venue.latitude
    json.longitude venue.longitude
  end
end

json.sets gig.sets.order(:start_offset) do |set|
  json.start_time set.start_at
  json.start_offset_time set.start_offset_time
  json.duration set.duration

  act = set.act
  json.act do
    json.id act.id
    json.name act.name
    json.genres act.genres
    json.location act.location if act.location
    json.country act.country if act.country
  end
end

json.prices gig.prices do |price|
  json.amount price.amount.format if price.amount
  json.description price.description if price.description
end
