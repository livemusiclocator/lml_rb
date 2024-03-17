# frozen_string_literal: true

json.array! @gigs do |gig|
  json.id gig.id
  json.name gig.name
  json.date gig.date
  json.tags gig.tags || []
  json.start_time gig.start_time
  json.finish_time gig.finish_time

  venue = gig.venue
  json.venue do
    json.id venue.id
    json.name venue.name
    json.address venue.address
    json.latitude venue.latitude
    json.longitude venue.longitude
  end

  headline_act = gig.headline_act
  json.headline_act do
    json.id headline_act.id
    json.name headline_act.name
    json.genres headline_act.genres
  end

  json.sets gig.sets do |set|
    json.start_time set.start_time

    act = set.act
    json.act do
      json.id act.id
      json.name act.name
      json.genres act.genres
    end
  end
end
