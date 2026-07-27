# frozen_string_literal: true

json.array! @acts do |act|
    json.id act.id
    json.name act.name
    json.genres act.genres
    json.location act.location if act.location
    json.country act.country if act.country

    json.bandcamp_url act.bandcamp_url if act.bandcamp_url
    json.facebook_url act.facebook_url if act.facebook_url
    json.instagram_url act.instagram_url if act.instagram_url
    json.linktree_url act.linktree_url if act.linktree_url
    json.musicbrainz_url act.musicbrainz_url if act.musicbrainz_url
    json.rym_url act.rym_url if act.rym_url
    json.spotify_url act.spotify_url if act.spotify_url
    json.website act.website if act.website
    json.wikipedia_url act.wikipedia_url if act.wikipedia_url
    json.youtube_url act.youtube_url if act.youtube_url

    json.upcoming_gigs Lml::Set.where(act_id: act.id).joins(:gig).where("gigs.date >= ?", Date.current).map(&:gig).uniq do |gig|
      json.id gig.id
      json.name gig.name
      json.date gig.date
      venue = gig.venue
      json.venue do
        json.id venue.id
        json.name venue.name
      end
    end
end