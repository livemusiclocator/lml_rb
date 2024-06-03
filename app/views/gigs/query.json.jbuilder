# frozen_string_literal: true

json.array! @gigs do |gig|
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

  headline_act = gig.headline_act
  if headline_act
    json.headline_act do
      json.id headline_act.id
      json.name headline_act.name
      json.genres headline_act.genres
    end
  end

  json.sets gig.sets do |set|
    json.start_time set.start_at
    json.start_offset_time set.start_offset_time
    json.duration set.duration

    act = set.act
    json.act do
      json.id act.id
      json.name act.name
      json.genres act.genres
    end
  end

  json.prices gig.prices do |price|
    json.amount price.amount.format if price.amount
    json.description price.description if price.description
  end
end
