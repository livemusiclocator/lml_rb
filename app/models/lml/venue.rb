# frozen_string_literal: true

module Lml
  class Venue < ApplicationRecord
    include Lml::Searchable

    SEARCH_COLUMNS = %w[name location].freeze

    scope :search, ->(query) { search_terms(query, SEARCH_COLUMNS).order(:name) }

    def self.ransackable_attributes(_auth_object = nil)
      %w[name location time_zone admin_user_id]
    end

    def self.ransackable_scopes(_auth_object = nil)
      [:with_admin_user]
    end

    scope :with_admin_user, lambda { |id|
      return where(admin_user_id: nil) if id == "none"

      where(admin_user_id: id)
    }

    def self.ransackable_associations(_auth_object = nil)
      %w[admin_user]
    end

    validates(
      :time_zone,
      inclusion: {
        in: Lml::Timezone::CANONICAL_TIMEZONES,
        message: "invalid time zone",
      },
    )

    has_many :gigs, dependent: :delete_all
    # What a venue page lists, for the same reasons as Lml::Act#upcoming_gigs:
    # `visible` because an unannounced or draft gig has no business on a public
    # page, `eager` because the view renders each gig's sets. No distinct - a gig
    # has the one venue, so nothing fans out the way an act's sets do.
    has_many :upcoming_gigs,
             -> { visible.eager.where(date: Date.current..) },
             class_name: "Lml::Gig", foreign_key: :venue_id, inverse_of: :venue
    has_many :uploads, dependent: :delete_all
    has_many :venue_managers, class_name: "Lml::VenueManager", foreign_key: :venue_id, dependent: :destroy
    has_many :managers, through: :venue_managers, source: :user
    belongs_to :admin_user, class_name: "Lml::AdminUser", optional: true
    # custom join to Web::Location - if available
    def location_record
      Web::Location.where("LOWER(internal_identifier) = LOWER(?)", location).first
    end
    scope :in_location, lambda { |location|
      if location == "anywhere"
        # "anywhere" means the main edition's selectable locations, not literally
        # every venue. A location left off that list is hidden: gigs can be
        # entered against it and worked on without showing up in the gig guide,
        # while `location=thatplace` still fetches them for whoever knows to ask.
        public_locations = Web::ExplorerConfig.public_location_identifiers

        # No config row, or an admin emptied the list. Falling back to everything
        # keeps the old behaviour rather than serving an empty gig guide.
        return where.not(location: %w[placeholder]) if public_locations.blank?

        return in_locations(public_locations)
      end
      # Until we sort out locations properly, asking for 'location=melbourne' will show you everything
      # in stkilda location and melbourne. Both spellings of Melbourne used to be
      # listed here by hand; in_locations lowers the column, so they no longer are.
      return in_locations(%w[melbourne stkilda]) if location == "melbourne"

      where(Venue.arel_table[:location].matches(location))
    }

    # The location column holds both "Melbourne" and "melbourne", so compare on
    # the lowered column rather than trusting what was typed in. Table qualified
    # because this is merged into a gigs query, and gigs has a location too.
    scope :in_locations, lambda { |identifiers|
      where("LOWER(venues.location) IN (?)", identifiers.map { |identifier| identifier.to_s.downcase })
    }

    # Venues with a gig - not hidden, not a draft - on or after this date. No upper bound, so a
    # venue with something coming up counts as active just as much as one that had a gig last week.
    scope :with_gigs_since, lambda { |date|
      # A subquery rather than a join, which would return one row per gig.
      where(id: Lml::Gig.visible.where(date: date..).select(:venue_id))
    }

    scope :named, ->(name) { where("LOWER(name) = ?", name.to_s.strip.downcase).order(:name) }

    scope :resolved, -> { where.not(address_components: {}) }

    # `@>` is subset matching, so this finds venues at this address *and* venues carrying extra
    # identity keys - a subpremise within the same building. The caller decides which it wanted.
    scope :at_address, lambda { |identity|
      # `@> '{}'` is true of every row, so a place with no identity components at all must match
      # nothing here rather than claiming the whole table.
      next none if identity.blank?

      where("address_components @> ?::jsonb", identity.to_json).order(:name)
    }

    # The part of the resolved address that decides whether two venues are at the same address.
    def address_identity
      (address_components || {}).slice(*Lml::Place::MATCH_KEYS).compact
    end

    def closed_permanently?
      google_business_status == Lml::Place::CLOSED_PERMANENTLY
    end

    # Google's place ids are url safe base64 - letters, digits, hyphen, underscore, and never a
    # space. Anything else in the column is one of Lml::VenuePlaceLookup's markers, recording a
    # lookup that found nothing or found too much.
    PLACE_ID = /\A[A-Za-z0-9_-]+\z/

    def google_place_marker?
      google_place_id.present? && !google_place_id.match?(PLACE_ID)
    end

    def label
      location.present? ? "#{name} (#{location})" : name
    end

    def search_label
      label
    end

    def tag_list
      (tags || []).join(", ")
    end

    def tag_list=(value)
      self.tags = value.split(",").map(&:strip)
    end

    def lat_lng
      return nil unless latitude && longitude

      [latitude, longitude].join(", ")
    end

    def lat_lng=(value)
      lat, lng = value.split(",").map(&:strip)
      return if lat.blank? && lng.blank?

      self.latitude = lat
      self.longitude = lng
    end
  end
end
