# frozen_string_literal: true

module Lml
  # Resolves one venue through the Places API, on demand, from the admin.
  #
  #   Lml::VenuePlaceLookup.call(venue)              # => :matched / :no_match / :ambiguous / :skipped
  #   Lml::VenuePlaceLookup.call(venue, force: true) # ask again anyway
  #
  # VenueBackfill does the same job in bulk for venues with recent gigs, and simply counts anything
  # it cannot settle. This is the single venue version, for somebody looking at one venue who wants
  # an answer now - so unlike the backfill it writes the *unsuccessful* outcomes down too, as a
  # marker in google_place_id, where the show page puts it in front of whoever asked. A venue that
  # Google has nothing useful to say about is a fact worth keeping; without it the only record of a
  # failed lookup is that nothing happened.
  #
  # Every call is billable, so anything at all in google_place_id - a real id or a marker - means
  # the question has been asked and the answer stands. `force` is the way to ask again, and is
  # deliberately not offered in the UI: it is an admin API parameter, so re-spending on a venue is
  # something you have to mean.
  #
  # See doc/google_sheets_venue_import.md.
  class VenuePlaceLookup
    REGION_CODE = "AU"

    SKIPPED = :skipped
    MATCHED = :matched
    NO_MATCH = :no_match
    AMBIGUOUS = :ambiguous

    # Written into google_place_id in place of an id. Both contain a space, which is what tells
    # them apart from a real one - see Lml::Venue#google_place_marker?.
    NO_MATCH_MARKER = "no match"
    AMBIGUOUS_MARKER = "ambiguous - %<count>d matches"

    def self.call(venue, force: false, places: GooglePlacesApiClient.new)
      new(venue, force: force, places: places).call
    end

    def initialize(venue, force: false, places: GooglePlacesApiClient.new)
      @venue = venue
      @force = force
      @places = places
    end

    def call
      return SKIPPED unless ask?

      found = @places.find(query, region_code: REGION_CODE)["places"] || []

      return mark(NO_MATCH_MARKER, NO_MATCH) if found.empty?
      return mark(format(AMBIGUOUS_MARKER, count: found.length), AMBIGUOUS) if found.length > 1

      # Place decides what of this a venue actually takes: the volatile business status always, and
      # everything else - lat/lng, address, postcode, time zone - only where the column is blank.
      # A filled column is somebody's research and Google is not a good enough reason to lose it.
      VenueBackfill.apply(@venue, Place.new(found.first))

      MATCHED
    end

    private

    def ask?
      @force || @venue.google_place_id.blank?
    end

    # The query the backfill uses: the name alone finds somewhere well known, and the address is
    # what separates two pubs sharing a name.
    def query
      [@venue.name, @venue.address].compact_blank.join(", ")
    end

    # `save(validate: false)` for the same reason VenueBackfill.apply does it: plenty of venues
    # predate the time_zone validation, and losing the record of a failed lookup because of an
    # unrelated invalid column would be the wrong trade.
    def mark(marker, outcome)
      @venue.google_place_id = marker
      @venue.save(validate: false)

      outcome
    end
  end
end
