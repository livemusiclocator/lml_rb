module Lml
  module Processors
    class SchemaOrgEvents
      def initialize(upload)
        @upload = upload
      end

      def process!
        JSON.parse(@upload.content).each do |data|
          next unless event?(data)

          name = data["name"]

          gig = find_or_create_gig(name)
          gig.description = data["description"]
          gig.date = data["endDate"]
          gig.start_time = data["startDate"]
          gig.ticketing_url = data["url"]
          append_venue(gig, data["location"])
          gig.save
        end
      end

      private

      def find_or_create_gig(name)
        gig = Lml::Gig.where("lower(name) = ?", name.downcase).first
        gig || Lml::Gig.create(name: name)
      end

      def append_venue(gig, data)
        return unless data.present?
        return unless data["@type"] == "Place"

        name = data["name"]

        venue = Lml::Venue.where("lower(name) = ?", name.downcase).first
        venue ||= Lml::Venue.create(name: name)
        append_geo(venue, data["geo"])
        append_address(venue, data["address"])
        venue.save

        gig.venue = venue
      end

      def append_geo(venue, data)
        return unless data.present?
        return unless data["@type"] == "GeoCoordinates"

        venue.latitude = data["latitude"]
        venue.longitude = data["longitude"]
      end

      def append_address(venue, data)
        return unless data.present?
        return unless data["@type"] == "PostalAddress"

        venue.address = [
          "#{data["streetAddress"]},",
          data["addressLocality"],
          data["addressRegion"],
          data["postalCode"],
        ].join(" ")
        venue.location = data["addressRegion"]
      end

      def event?(data)
        data["@context"] == "http://schema.org" && data["@type"] == "Event"
      end
    end
  end
end
