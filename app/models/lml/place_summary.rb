# frozen_string_literal: true

module Lml
  # The parts of a venue's stored Google answer worth showing somebody looking after the venue:
  # whether it is still trading, what Google thinks it is, its hours and access, and where Google
  # now says something different from what we have. Reads google_place only, so it costs nothing.
  class PlaceSummary
    # Types that say nothing about what a place is.
    GENERIC_TYPES = %w[point_of_interest establishment food store].freeze

    # The columns a person can bring into line with Google from the edit page's refresh. Not the
    # map link: it only ever comes from Google, so it can be missing but never disagree.
    COMPARED = %i[name address website phone].freeze

    ACCESSIBILITY = {
      "wheelchairAccessibleEntrance" => "entrance",
      "wheelchairAccessibleSeating" => "seating",
      "wheelchairAccessibleRestroom" => "restroom",
      "wheelchairAccessibleParking" => "parking",
    }.freeze

    def initialize(venue)
      @venue = venue
      @payload = venue.google_place || {}
      @place = Place.new(@payload)
    end

    def present?
      @payload.present?
    end

    def name
      @place.name
    end

    def address
      @place.address
    end

    def maps_url
      @place.maps_url
    end

    def fetched_at
      @venue.google_place_fetched_at
    end

    # OPERATIONAL, CLOSED_TEMPORARILY or CLOSED_PERMANENTLY.
    def status
      @place.business_status
    end

    def kind
      @payload.dig("primaryTypeDisplayName", "text")
    end

    def types
      (@payload["types"] || [])
        .excluding(*GENERIC_TYPES, @payload["primaryType"])
        .map { |type| type.humanize(capitalize: false) }
        .first(4)
    end

    # One line per day, Monday first, as Google writes them: "Monday: 4:00 PM – 1:00 AM".
    def hours
      @payload.dig("regularOpeningHours", "weekdayDescriptions") || []
    end

    def hours_on(date)
      hours[(date.wday + 6) % 7]
    end

    # { accessible: ["entrance"], not_accessible: ["parking"] }, leaving out what Google does not know.
    def accessibility
      options = @payload["accessibilityOptions"] || {}
      known = ACCESSIBILITY.select { |key, _| options.key?(key) }

      {
        accessible: known.select { |key, _| options[key] }.values,
        not_accessible: known.reject { |key, _| options[key] }.values,
      }
    end

    # Where Google and the venue disagree, as { column => [google's, ours] }. Only what Google has
    # an answer for - a website it does not know is not a disagreement.
    def differences
      google = @place.form_attributes.slice(*COMPARED)

      google.each_with_object({}) do |(column, theirs), result|
        ours = @venue[column]
        result[column] = [theirs, ours] unless same?(column, theirs, ours)
      end
    end

    private

    # An address is ours whether it is Google's short form, which lookups now write, or the long
    # one with state, postcode and country, which they wrote before.
    def same?(column, theirs, ours)
      forms = column == :address ? [theirs, @place.formatted_address] : [theirs]
      forms.compact.any? { |form| normalise(column, form) == normalise(column, ours) }
    end

    # Google writes the same website and phone number in more than one way - with or without www
    # and https, or with the phone number's spaces and brackets moved.
    def normalise(column, value)
      value = value.to_s.strip

      case column
      when :website then value.downcase.sub(%r{\Ahttps?://(www\.)?}, "").chomp("/")
      when :phone then value.gsub(/\D/, "")
      else value
      end
    end
  end
end
