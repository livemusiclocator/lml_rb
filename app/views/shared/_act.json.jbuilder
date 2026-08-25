# frozen_string_literal: true

# The act as every public endpoint renders it. Extracted because gigs#show and
# gigs#query already carried a copy each and had started to drift, and acts#show
# would have been a third - a front end reading an act from a gig and the same
# act from /acts/:id has to get the same shape.

json.id act.id
json.name act.name
json.location act.location if act.location
json.country act.country if act.country
json.genres act.genres

json.website act.website if act.website

json.bandcamp_url act.bandcamp_url if act.bandcamp_url
json.facebook_url act.facebook_url if act.facebook_url
json.instagram_url act.instagram_url if act.instagram_url
json.linktree_url act.linktree_url if act.linktree_url
json.musicbrainz_url act.musicbrainz_url if act.musicbrainz_url
json.rym_url act.rym_url if act.rym_url
json.spotify_url act.spotify_url if act.spotify_url
json.wikipedia_url act.wikipedia_url if act.wikipedia_url
json.youtube_url act.youtube_url if act.youtube_url
