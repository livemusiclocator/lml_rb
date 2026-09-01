# frozen_string_literal: true

module Lml
  # The numbers behind the Coverage panel on the admin dashboard: how many venues
  # sit in the regions the gig guide actually serves, how many of those we are
  # currently profiling gigs at, and how many gigs a week that adds up to.
  #
  # Three grouped counts over two small tables - a few milliseconds for the whole
  # panel - so the dashboard works them out per request rather than caching them
  # and then having to explain why a number is stale.
  class CoverageStats
    # A region is live when it is publicly selectable in the main edition: the
    # same list `location=anywhere` resolves to, and the same one that decides
    # whether a venue shows up in the gig guide at all. "anywhere" stands for
    # that whole list rather than being a region of its own.
    PSEUDO_LOCATIONS = %w[anywhere].freeze

    # `locations` carries no state column, so naming them is the only way to say
    # "Victoria". A live region missing from this list still gets its own row -
    # it just sits outside the Victorian totals, rather than quietly inflating a
    # number we go and repeat in public.
    VICTORIAN = %w[
      melbourne stkilda geelong bendigo castlemaine goldfields grampians queenscliff
    ].freeze

    WEEKS = 52
    ACTIVE_DAYS = 90

    Region = Struct.new(
      :identifier, :name, :victorian, :venues, :active, :recently_active, :gigs,
      keyword_init: true,
    ) do
      def gigs_per_week = (gigs / WEEKS.to_f).round(1)
      def victorian? = victorian
    end

    def initialize(today: Date.current)
      @today = today
    end

    attr_reader :today

    # The window every rate on the panel is measured over: the 52 whole weeks up
    # to yesterday. Today is left out because it is a partial day, and a partial
    # day drags a weekly average down for no reason anyone can see on the page.
    def period = (today - (WEEKS * 7))..(today - 1)

    # Victorian regions first and biggest first within that, so the Victorian
    # total on the dashboard follows the rows it is a total of.
    def regions
      @regions ||= live_identifiers.map { |identifier| region_for(identifier) }
                                   .sort_by { |region| [region.victorian? ? 0 : 1, -region.venues] }
    end

    def victorian_regions = regions.select(&:victorian?)

    def venues = victorian_regions.sum(&:venues)
    def active_venues = victorian_regions.sum(&:active)
    def recently_active_venues = victorian_regions.sum(&:recently_active)
    def gigs = victorian_regions.sum(&:gigs)
    def gigs_per_week = (gigs / WEEKS.to_f).round(1)

    # Venues whose location is not a live region, commonest first. Some of these
    # are interstate and some are regions we hold data for without publishing;
    # the rest are spelling variants - "St Kilda" is not "stkilda" - and a venue
    # in one of those is invisible to the gig guide, so it is worth seeing.
    def unserved_locations
      @unserved_locations ||= venues_by_location
                              .except(*live_identifiers)
                              .reject { |location, _| location.blank? }
                              .sort_by { |_, count| -count }
    end

    def unserved_venues = unserved_locations.sum { |_, count| count }

    # The tail of this is long - fifty odd locations, most of them a single venue
    # - and the dashboard has panels below it, so it shows the head and says how
    # much it left out rather than running to a screen and a half.
    LISTED = 10

    def listed_unserved_locations = unserved_locations.first(LISTED)
    def unlisted_unserved_locations = [unserved_locations.size - LISTED, 0].max

    private

    def region_for(identifier)
      Region.new(
        identifier: identifier,
        name: location_names[identifier] || identifier.titleize,
        victorian: VICTORIAN.include?(identifier),
        venues: venues_by_location[identifier],
        active: active_by_location[identifier],
        recently_active: recently_active_by_location[identifier],
        gigs: gigs_by_location[identifier],
      )
    end

    def live_identifiers
      @live_identifiers ||= begin
        identifiers = Web::ExplorerConfig.public_location_identifiers
        identifiers.map { |identifier| identifier.to_s.downcase } - PSEUDO_LOCATIONS
      end
    end

    def location_names
      @location_names ||= Web::Location.pluck(:internal_identifier, :name)
                                       .to_h { |identifier, name| [identifier.downcase, name] }
    end

    # Keyed by the lowered location column, which is exactly the form a location's
    # internal_identifier takes, so these hashes are looked up by identifier above.
    def venues_by_location
      @venues_by_location ||= counts_by_location(Lml::Venue.all)
    end

    def active_by_location = @active_by_location ||= venues_with_gigs_since(period.begin)

    def recently_active_by_location
      @recently_active_by_location ||= venues_with_gigs_since(today - ACTIVE_DAYS)
    end

    def venues_with_gigs_since(date)
      counts_by_location(Lml::Venue.with_gigs_since(date))
    end

    def gigs_by_location
      @gigs_by_location ||= counts_by_location(Lml::Gig.visible.where(date: period).joins(:venue))
    end

    # Defaulting to 0 so a live region with no venues at all - a location added to
    # the config ahead of the data - still reads as a number rather than a nil.
    def counts_by_location(relation)
      relation.group("LOWER(venues.location)").count.tap { |counts| counts.default = 0 }
    end
  end
end
