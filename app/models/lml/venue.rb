module Lml
  class Venue < ApplicationRecord
    def self.ransackable_attributes(_auth_object = nil)
      %w[name location time_zone]
    end

    def self.ransackable_associations(_auth_object = nil)
      []
    end

    def self.find_or_create_venue(name:, time_zone:, details: {})
      name = CGI.unescapeHTML(name.strip)

      venue = Lml::Venue.where("lower(name) = ?", name.downcase)
                        .where("lower(time_zone) = ?", time_zone.downcase)
                        .first
      venue ||= Lml::Venue.create!(name: name, time_zone: time_zone)
      venue.update!(details) unless details.empty?
      venue
    end

    validates(
      :time_zone,
      inclusion: {
        in: Lml::Timezone::CANONICAL_TIMEZONES,
        message: "invalid time zone",
      },
    )

    has_many :gigs

    def label
      "#{name} (#{location})"
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
