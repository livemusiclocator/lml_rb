# frozen_string_literal: true

module Lml
  # Resolves venues we already have through the Places API, so that a sheet import can match them on
  # their structured address instead of falling back to their names.
  #
  #   Lml::VenueBackfill.call(dry_run: true)   # what it would do, spends nothing
  #   Lml::VenueBackfill.call                  # venues with gigs in the last 3 months
  #   Lml::VenueBackfill.call(months: 12)
  #
  #   # => { "filled" => 240, "not found" => 31, "ambiguous" => 13 }
  #
  # Scoped to venues with recent gigs rather than every venue, because a venue nobody has programmed
  # in a year is as likely to be a typo or a duplicate as a real place, and resolving those just
  # gives the mistakes a structured address that future imports will match against.
  #
  # The window is not about cost - the whole table fits inside the Places free monthly allowance. It
  # is about not lending authority to rows that have not earned it.
  #
  # See doc/google_sheets_venue_import.md.
  class VenueBackfill
    DEFAULT_MONTHS = 3

    REGION_CODE = "AU"

    FILLED = "filled"
    ALREADY_RESOLVED = "already resolved"
    NOT_FOUND = "not found"
    AMBIGUOUS = "ambiguous"
    FAILED = "failed"

    # Writes a place onto a venue. Shared with the sheet import, which does exactly the same thing
    # to a venue it has just matched.
    #
    # `save(validate: false)` because plenty of venues predate the time_zone validation and would
    # otherwise refuse to save at all - and refusing to record what Places said about a venue
    # because of an unrelated invalid column would be the wrong trade.
    def self.apply(venue, place)
      venue.assign_attributes(place.attributes_for(venue))

      venue.save(validate: false)
    end

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
      return dry_run_counts if @dry_run

      scope.find_each { |venue| @counts[outcome_for(venue)] += 1 }

      @counts
    end

    # What a real run would cost in Places calls, without making any. Worth looking at first, since
    # this walks hundreds of venues and every unresolved one is a billable request.
    def dry_run_counts
      {
        "venues in scope" => scope.count,
        "already resolved" => scope.resolved.count,
        "places calls" => scope.where(address_components: {}).count,
      }
    end

    private

    def scope
      Venue.with_gigs_since(@months.months.ago.to_date)
    end

    def outcome_for(venue)
      resolve(venue)
    rescue StandardError => e
      Rails.logger.error("venue backfill failed for #{venue.id}: #{e.class}: #{e.message}")

      FAILED
    end

    def resolve(venue)
      # Only ever fills a gap. A venue already carrying components was resolved by an earlier run or
      # by an import, and re-resolving it would spend a request to overwrite it with the same thing.
      return ALREADY_RESOLVED if venue.address_components.present?

      found = @places.find(query_for(venue), region_code: REGION_CODE)["places"] || []

      return NOT_FOUND if found.empty?
      # No colour to fall back on and no sheet to write into, so an ambiguous venue is simply left
      # alone for a person to look at. Lml::Venue.with_gigs_since(...) minus .resolved lists them.
      return AMBIGUOUS if found.length > 1

      self.class.apply(venue, Place.new(found.first))

      FILLED
    end

    def query_for(venue)
      [venue.name, venue.address].compact_blank.join(", ")
    end
  end
end
