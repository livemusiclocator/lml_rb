# frozen_string_literal: true

module Lml
  # Works through a worksheet of venues, resolving each row through the Places API, matching it
  # against the venues we already have, creating it if it is new, and writing what became of it back
  # into the row it came from.
  #
  #   Lml::VenueImport.call("https://docs.google.com/spreadsheets/d/.../edit")
  #   # => { "created" => 12, "matched" => 3, "ambiguous" => 1 }
  #
  # A row that already carries a venue_id is left exactly as it is, so adding rows to the bottom of
  # the sheet and running this again touches only the new ones. Nothing is created for a row the
  # importer is not sure about - it is coloured for someone to look at instead, because a wrong match
  # silently attaches gigs to the wrong venue and that is far more expensive to unpick later.
  #
  # See doc/google_sheets_venue_import.md for the credentials, the sheet's columns and the reasoning
  # behind what is matched on.
  class VenueImport
    WORKSHEET = "venues"

    # Biases the Places lookup, which matters because a bare venue name is often ambiguous across
    # countries - there is a Corner Hotel in more places than Richmond.
    REGION_CODE = "AU"

    DEFAULT_TIME_ZONE = "Australia/Melbourne"

    COLUMN_VENUE_ID = "venue_id"
    COLUMN_STATUS = "import_status"
    OUTPUT_COLUMNS = [COLUMN_VENUE_ID, COLUMN_STATUS].freeze

    # Sheet header => venue attribute. These are assigned before anything Places resolved, so a
    # value someone put in the sheet always wins over Google's - `address` and `time_zone` are here
    # precisely because Places offers both and the sheet should beat it.
    ATTRIBUTES = {
      "name" => :name,
      "address" => :address,
      "time_zone" => :time_zone,
      "location" => :location,
      "website" => :website,
      "email" => :email,
      "phone" => :phone,
      "facebook_url" => :facebook_url,
      "instagram_url" => :instagram_url,
      "location_url" => :location_url,
      "capacity" => :capacity,
      "vibe" => :vibe,
      "notes" => :notes,
      "tags" => :tag_list,
    }.freeze

    CREATED = "created"
    MATCHED = "matched"
    SKIPPED = "already imported"
    NOT_FOUND = "not found"
    AMBIGUOUS = "ambiguous"
    SEVERAL_VENUES = "several venues"
    SAME_BUILDING = "same building"
    NO_NAME = "no name"
    FAILED = "failed"

    # A vague query can return dozens of places. Naming a few is enough to see why it was too vague;
    # listing all of them just makes an unreadable spreadsheet cell.
    PLACES_TO_NAME = 5

    # `bucket` is what the row is counted as, `status` the sentence written into it - the same thing
    # for a clean row, and the bucket plus an explanation for one needing attention.
    Outcome = Struct.new(:bucket, :status, :venue_id, :colour, keyword_init: true)

    def self.call(url, worksheet: WORKSHEET, sheet: Sheet.new(url), places: GooglePlacesApiClient.new)
      new(sheet: sheet, worksheet: worksheet, places: places).call
    end

    def initialize(sheet:, worksheet: WORKSHEET, places: GooglePlacesApiClient.new)
      @sheet = sheet
      @worksheet = worksheet
      @places = places
      @counts = Hash.new(0)
    end

    # Each row is written as soon as it is decided rather than all of them at the end, so a run is
    # something you can watch happen in the sheet you are already looking at, and a run that is
    # interrupted keeps everything it has already done.
    def call
      @sheet.ensure_headers(worksheet: @worksheet, headers: OUTPUT_COLUMNS)

      @sheet.rows(worksheet: @worksheet).each_with_index do |row, index|
        record(outcome_for(row), index)
      end

      @counts
    end

    private

    # One row that raises is one row for someone to go and look at, not a reason to abandon the rest
    # of the sheet. The message goes into the sheet because that is where the work is happening - an
    # error only in the logs is invisible to whoever is watching.
    def outcome_for(row)
      process(row)
    rescue StandardError => e
      Rails.logger.error("venue import row failed: #{e.class}: #{e.message}")

      attention(FAILED, detail: e.message.truncate(200))
    end

    def process(row)
      return Outcome.new(bucket: SKIPPED) if row[COLUMN_VENUE_ID].present?
      return attention(NO_NAME) if row["name"].blank?

      places = find_places(row)

      return attention(NOT_FOUND) if places.empty?
      return attention(AMBIGUOUS, detail: named(places)) if places.length > 1

      resolve(row, Place.new(places.first))
    end

    def resolve(row, place)
      at_address = Venue.at_address(place.identity)
      exact = at_address.select { |venue| venue.address_identity == place.identity }

      # `@>` is subset matching, so a venue carrying identity keys we did not ask for - typically a
      # subpremise - is a different address in the same building rather than this one. Which of the
      # two a row means is a judgement call rather than an import decision.
      return attention(SAME_BUILDING, detail: names_of(at_address)) if exact.empty? && at_address.any?

      decide(row, exact.presence || by_name(row), place)
    end

    def decide(row, candidates, place)
      # Usually a venue and a venue inside it - a bar within a pub.
      return attention(SEVERAL_VENUES, detail: names_of(candidates)) if candidates.length > 1

      venue = candidates.first

      venue ? matched(venue, place) : created(row, place)
    end

    def matched(venue, place)
      # Filling in the places data is what lets the next run match this venue structurally rather
      # than falling back to its name again.
      VenueBackfill.apply(venue, place)

      Outcome.new(bucket: MATCHED, status: MATCHED, venue_id: venue.id, colour: :done)
    end

    # The sheet's values are assigned first so that they win: what Places settles only fills in what
    # the row left blank. The time zone default is last, for a row and a place that both had none.
    def created(row, place)
      venue = Venue.new(from_sheet(row))
      venue.assign_attributes(place.attributes_for(venue))
      venue.time_zone = DEFAULT_TIME_ZONE if venue.time_zone.blank?
      venue.save!

      Outcome.new(bucket: CREATED, status: CREATED, venue_id: venue.id, colour: :done)
    end

    def from_sheet(row)
      ATTRIBUTES.filter_map { |header, attribute| [attribute, row[header]] if row[header].present? }.to_h
    end

    # Falling back to the name is what makes the first run useful, since no existing venue has
    # components until something matches it and fills them in.
    def by_name(row)
      Venue.named(row["name"]).to_a
    end

    def names_of(venues)
      venues.map(&:name).join(" | ")
    end

    def find_places(row)
      @places.find(query_for(row), region_code: REGION_CODE)["places"] || []
    end

    def query_for(row)
      [row["name"], row["address"]].compact.join(", ")
    end

    def named(places)
      names = places.first(PLACES_TO_NAME).map { |place| place.dig("displayName", "text") }
      names << "and #{places.length - PLACES_TO_NAME} more" if places.length > PLACES_TO_NAME

      "#{places.length} places: #{names.join(" | ")}"
    end

    def attention(bucket, detail: nil)
      Outcome.new(bucket: bucket, status: [bucket, detail].compact.join(" - "), colour: :attention)
    end

    def record(outcome, index)
      @counts[outcome.bucket] += 1

      @sheet.write_row(
        worksheet: @worksheet,
        index: index,
        cells: cells_for(outcome),
        colour: outcome.colour,
      )
    end

    # A skipped row is left completely alone, still coloured by whichever run imported it.
    def cells_for(outcome)
      return {} if outcome.bucket == SKIPPED

      { COLUMN_STATUS => outcome.status, COLUMN_VENUE_ID => outcome.venue_id }
    end
  end
end
