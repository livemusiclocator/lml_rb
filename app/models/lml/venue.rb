module Lml
  # special handling for locations we may wish to move to database
  LocationParameters = {"stkilda"=>
                        {postcodes:[3182],
                         location:"melbourne"}
                       }
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

    scope :in_location, ->(location) {
      if LocationParameters[location]
        params = LocationParameters[location]
        return where(postcode: params[:postcodes]).where(location: params[:location])
      else
        return where("lower(location) = ?", location)
      end
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
