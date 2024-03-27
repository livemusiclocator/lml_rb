module Lml
  module Processors
    class SchemaOrgEvents
      def initialize(upload)
        @upload = upload
      end

      def process!
        @upload.gig_ids = []
        JSON.parse(@upload.content).each do |data|
          process_event(data)
          (data["@graph"] || []).each do |child_element|
            process_event(child_element)
          end
        end
        @upload.save!
      end

      private

      def process_event(data)
        return unless event?(data)

        Time.zone = data["timezone"] if data["timezone"]

        name = data["name"] || ""
        name = CGI.unescapeHTML(name.strip)

        date = data["startDate"].slice(0, 10) if data["startDate"].present?
        venue = @upload.venue
        venue ||= find_or_create_venue(data["location"])

        gig = find_or_create_gig(name, date, venue)
        gig.description = CGI.unescapeHTML(data["description"]) if data["description"]

        gig.start_time = data["startDate"]
        gig.start_offset_time = gig.start_time.strftime("%H:%M") if gig.start_time

        gig.ticketing_url = data["url"]
        gig.status = status(data)
        append_acts(gig, data["performers"])
        gig.save!
        @upload.gig_ids << gig.id
      end

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

      def find_or_create_gig(name, date, venue)
        gig = Lml::Gig.where(date: date, venue: venue).where("lower(name) = ?", name.downcase).first
        gig || Lml::Gig.create(
          name: name,
          date: date,
          venue: venue,
        )
      end

      RIDICULOUS_NONSENSE = [
        "brunswick ballroom homepage",
        "brunswick ballroom",
        "howler",
        "hwlr",
        "northcote theatre",
      ]

      def append_acts(gig, data_list)
        return unless data_list.present?

        acts = []
        gig.sets.destroy_all
        data_list.each do |data|
          next unless data["@type"] == "Person"

          name = CGI.unescapeHTML(data["name"].strip)
          next if RIDICULOUS_NONSENSE.include?(name.downcase)

          act = Lml::Act.where("lower(name) = ?", name.downcase).first
          act ||= Lml::Act.create(name: name)
          Lml::Set.create(gig: gig, act: act)
          acts << act
        end
        gig.headline_act = acts.first
      end

      def find_or_create_venue(data)
        return unless data.present?
        return unless data["@type"] == "Place"

        name = CGI.unescapeHTML(data["name"].strip)

        venue = Lml::Venue.where("lower(name) = ?", name.downcase).first
        venue ||= Lml::Venue.create(name: name)
        append_geo(venue, data["geo"])
        append_address(venue, data["address"])
        venue.save

        venue
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
