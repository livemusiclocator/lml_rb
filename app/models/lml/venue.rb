# frozen_string_literal: true

module Lml
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
    # custom join to LML::Location - if available
    def location_record
      Lml::Location.where("LOWER(internal_identifier) = LOWER(?)", location).first
    end
    scope :in_location, lambda { |location|
      # TODO: unreleased locations !
      if location == "anywhere"
        return where.not(location: %w[Geelong geelong castlemaine goldfields Goldfields Castlemaine])
      end
      # Until we sort out locations properly, asking for 'location=melbourne' will show you everything
      # in stkilda location and melbourne (and "Melbourne"! )
      return where(location: %w[Melbourne melbourne stkilda]) if location == "melbourne"

      where(Venue.arel_table[:location].matches(location))
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
