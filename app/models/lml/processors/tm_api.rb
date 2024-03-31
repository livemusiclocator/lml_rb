module Lml
  module Processors
    class TmApi
      def initialize(upload)
        @upload = upload
      end

      def scrape
        return unless @upload.source.start_with?("https://")

        docs = []

        page = 0
        finished = false

        until finished
          response = Faraday.get("#{@upload.source}&page=#{page}")
          content = JSON.parse(response.body)

          docs += content["events"]

          page += 1
          finished = content["events"].empty?
        end

        @upload.update!(content: JSON.pretty_generate(docs))
      end

      def process!
        @upload.gig_ids = []
        JSON.parse(@upload.content).each do |data|
          process_event(data)
        end
        @upload.save!
      end

      private

      def process_event(data)
        venue = @upload.venue

        time_zone = venue.time_zone if venue
        time_zone = @upload.time_zone if time_zone.blank?
        time_zone = Lml::Timezone.convert(data["timeZone"]) if time_zone.blank?

        Time.zone = time_zone

        venue ||= Lml::Venue.find_or_create_venue(
          name: data["venue"]["name"],
          time_zone: time_zone,
          details: {
            address: [
              data["venue"]["addressLineOne"],
              data["venue"]["city"],
              data["venue"]["state"],
              data["venue"]["code"],
            ].join(", "),
            latitude: data["venue"]["latitude"],
            longitude: data["venue"]["longitude"],
            location: data["venue"]["state"],
            postcode: data["venue"]["code"],
          },
        )

        name = data["title"] || ""
        name = CGI.unescapeHTML(name.strip)

        start_time = data["dates"]["startDate"]
        return unless start_time

        date = start_time.slice(0, 10)

        gig = Lml::Gig.find_or_create_gig(
          name: name,
          date: date,
          venue: venue,
          details: {
            start_time: start_time,
            ticketing_url: data["url"],
            status: status(data),
          },
        )

        gig.start_offset_time = gig.start_time.strftime("%H:%M")
        append_acts(gig, data["artists"])

        gig.save!

        @upload.gig_ids << gig.id
      end

      def status(data)
        return "cancelled" if data["cancelled"]
        return "cancelled" if data["postponed"]
        return "cancelled" if data["rescheduled"]
        return "draft" if data["tba"]

        "confirmed"
      end

      def append_acts(gig, list)
        return unless list.present?

        acts = []
        gig.sets.destroy_all
        list.each do |data|
          name = CGI.unescapeHTML(data["name"].strip)

          act = Lml::Act.where("lower(name) = ?", name.downcase).first
          act ||= Lml::Act.create(name: name)
          Lml::Set.create(gig: gig, act: act)
          acts << act
        end
        gig.headline_act = acts.first
      end
    end
  end
end
