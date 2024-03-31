# frozen_string_literal: true

module Eventfinda
  class Location
    class Point
      include ActiveModel::Model
      attr_accessor :lat, :lng

      def to_schema_org_builder
        Jbuilder.new do |geo|
          geo.set! "@type", :GeoCoordinates
          geo.latitude lat
          geo.longitude lng
        end
      end
    end

    include ActiveModel::Model
    attr_accessor :count_current_events, :description, :id, :images, :is_venue, :name, :point, :summary, :url_slug

    def initialize(address, timezone, raw)
      super(raw)
      @address = address
      @timezone = Lml::Timezone.convert(timezone)
      @point = Point.new(raw[:point])
    end

    def to_schema_org_builder
      Jbuilder.new do |location|
        location.set! "@type", :Place
        location.name name
        location.timezone @timezone
        location.location (@timezone || "").split("/").last
        location.address @address
        location.sameAs "https://www.eventfinda.com.au/venue/#{url_slug}"
        location.geo point.to_schema_org_builder if point
      end
    end
  end
end
