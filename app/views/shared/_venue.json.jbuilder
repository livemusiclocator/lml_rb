# frozen_string_literal: true

# The venue as every public endpoint renders it - see shared/_act for why these
# are partials rather than a copy per template.

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
