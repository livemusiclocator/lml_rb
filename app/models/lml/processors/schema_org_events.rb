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
          gig.status = status(data)
          append_venue(gig, data["location"])
          append_acts(gig, data["performers"])
          gig.save
        end
      end

      private

      def status(data)
        case (data["eventStatus"] || "").split("/").last
        when "EventScheduled", "EventRescheduled"
          "confirmed"
        when "EventCancelled"
          "cancelled"
        else
          "draft"
        end
      end

      def event?(data)
        %w[http://schema.org https://schema.org].include?(data["@context"]) && %w[Event MusicEvent].include?(data["@type"])
      end

      def find_or_create_gig(name)
        gig = Lml::Gig.where("lower(name) = ?", name.downcase).first
        gig || Lml::Gig.create(name: name)
      end

      def append_acts(gig, data_list)
        return unless data_list.present?

        acts = []
        gig.sets.destroy_all
        data_list.each do |data|
          next unless data["@type"] == "Person"

          name = CGI.unescapeHTML(data["name"])
          next if ["northcote theatre", "howler", "hwlr"].include?(name.downcase)

          act = Lml::Act.where("lower(name) = ?", name.downcase).first
          act ||= Lml::Act.create(name: name)
          Lml::Set.create(gig: gig, act: act)
          acts << act
        end
        gig.headline_act = acts.first
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
    end
  end
end
