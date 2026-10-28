# frozen_string_literal: true

module Lml
  # Fetches the whole Places answer for venues that were resolved before google_place existed, when
  # lookups asked for a handful of fields and kept only what fitted into columns.
  #
  #   Lml::GooglePlaceBackfill.call(dry_run: true)   # what it would do, spends nothing
  #   Lml::GooglePlaceBackfill.call                  # venues with gigs in the last 12 months
  #   Lml::GooglePlaceBackfill.call(months: 3)
  #
  #   # => { "filled" => 395, "place id changed" => 2, "failed" => 1 }
  #
  # Place Details by the id we already hold rather than Text Search, because the venue is already
  # settled: there is no query to get wrong and no second candidate to be ambiguous about, and a
  # Details call is cheaper. Venues that already have google_place are not in scope at all, so a
  # second run only spends on what the first one failed.
  #
  # See doc/google_sheets_venue_import.md.
  class GooglePlaceBackfill
    DEFAULT_MONTHS = 12

    FILLED = "filled"
    PLACE_ID_CHANGED = "place id changed"
    FAILED = "failed"

    def self.call(months: DEFAULT_MONTHS, dry_run: false, places: GooglePlacesApiClient.new)
      new(months: months, dry_run: dry_run, places: places).call
    end

    def initialize(months: DEFAULT_MONTHS, dry_run: false, places: GooglePlacesApiClient.new)
      @months = months
      @dry_run = dry_run
      @places = places
      @counts = Hash.new(0)
    end

    def call
      return { "places calls" => scope.count } if @dry_run

      scope.find_each { |venue| @counts[outcome_for(venue)] += 1 }

      @counts
    end

    private

    # Lml::VenuePlaceLookup's markers live in google_place_id too, and asking Google for the place
    # called "no match" would spend a request on a 400. Venue::PLACE_ID, in SQL.
    def scope
      Venue.with_gigs_since(@months.months.ago.to_date)
        .where(google_place: nil)
        .where("google_place_id ~ '^[A-Za-z0-9_-]+$'")
    end

    def outcome_for(venue)
      fetch(venue)
    rescue StandardError => e
      Rails.logger.error("google place backfill failed for #{venue.id}: #{e.class}: #{e.message}")

      FAILED
    end

    def fetch(venue)
      place = Place.new(@places.details(venue.google_place_id))

      # Google does reissue ids, answering the old one with the new. Whether the venue should follow
      # is the same identity question Place::IDENTITY refuses to settle automatically, so it is left
      # for a person, and nothing is written - the answer would describe a place the venue is not
      # recorded as being.
      return PLACE_ID_CHANGED if place.id != venue.google_place_id

      VenueBackfill.apply(venue, place)

      FILLED
    end
  end
end
