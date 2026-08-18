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
        # TODO: this could just be removed but I am in a bit of rush so this will do
        return where.not(location: %w[placeholder])
      end
      # Until we sort out locations properly, asking for 'location=melbourne' will show you everything
      # in stkilda location and melbourne (and "Melbourne"! )
      return where(location: %w[Melbourne melbourne stkilda]) if location == "melbourne"

      where(Venue.arel_table[:location].matches(location))
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
