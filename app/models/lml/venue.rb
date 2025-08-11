# frozen_string_literal: true

module Lml
  # special handling for locations we may wish to move to database
  POSTCODES = {
    "stkilda" => [3182, 3183, 3185],
  }.freeze

  class Venue < ApplicationRecord
    def self.ransackable_attributes(_auth_object = nil)
      %w[name location time_zone]
    end

    def self.ransackable_associations(_auth_object = nil)
      []
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

    scope :in_location, lambda { |location|
      # TODO: unreleased locations !
      if location == "anywhere"
        return where.not(location: %w[Geelong geelong castlemaine goldfields Goldfields Castlemaine])
      end

      postcodes = POSTCODES[location]
      in_location_filter = where(Venue.arel_table[:location].matches(location))

      # will remove postcode stuff shortly, once all the things are inside
      return in_location_filter.or(where(postcode: postcodes)) if postcodes

      in_location_filter
    }

    def label
      "#{name} (#{location})"
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
