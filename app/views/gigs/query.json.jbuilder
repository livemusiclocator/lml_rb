# frozen_string_literal: true

json.array! @gigs do |gig|
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
  json.genre_tags gig.published_genre_tags || []

  venue = gig.venue
  if venue
    json.venue do
      json.id venue.id
      json.name venue.name
      json.address venue.address
      json.capacity venue.capacity
      json.website venue.website
      json.postcode venue.postcode
      json.vibe venue.vibe
      json.tags venue.tags || []
      json.location_url venue.location_url
      json.latitude venue.latitude
      json.longitude venue.longitude
    end
  end

  json.sets gig.sets.sort_by{ |set| set.start_offset || 0} do |set|
    json.start_time set.start_time
    json.start_timestamp set.start_timestamp
    json.duration set.duration
    json.finish_time set.finish_time
    json.finish_timestamp set.finish_timestamp

    act = set.act
    json.act do
      json.id act.id
      json.name act.name
      json.location act.location if act.location
      json.country act.country if act.country
      json.genres act.genres

      json.website act.website if act.website
      json.instagram_url act.instagram_url if act.instagram_url
      json.facebook_url act.facebook_url if act.facebook_url
      json.linktree_url act.linktree_url if act.linktree_url
      json.bandcamp_url act.bandcamp_url if act.bandcamp_url
      json.musicbrainz_url act.musicbrainz_url if act.musicbrainz_url
      json.rym_url act.rym_url if act.rym_url
      json.wikipedia_url act.wikipedia_url if act.wikipedia_url
      json.youtube_url act.youtube_url if act.youtube_url
    end
  end

  json.prices gig.prices do |price|
    json.amount price.amount.format if price.amount
    json.description price.description if price.description
  end
end
