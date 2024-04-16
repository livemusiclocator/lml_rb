module Lml
  module Processors
    class Clipper
      def initialize(upload)
        @upload = upload
      end

      def process!
        @upload.gig_ids = []

        details = extract_details(@upload.content.lines)

        @upload.source = details[:url] if details[:url]

        venue = @upload.venue

        unless venue && details[:name].present? && details[:date].present?
          @upload.status = "Failed"
          @upload.error_description = "A venue, date and gig name is required"
          @upload.save!
          return
        end

        gig = Lml::Gig.find_or_create_gig(
          name: details[:name],
          date: details[:date],
          venue: venue,
        )

        append_prices(gig, details[:prices])
        gig.tags = details[:tags] if details[:tags].present?
        append_acts(gig, details[:acts])
        append_date_time(gig, details[:date], details[:time])
        gig.save

        @upload.status = "Succeeded"
        @upload.error_description = ""
        @upload.gig_ids << gig.id
        @upload.save!
      end

      private

      def extract_details(lines)
        {}.tap do |details|
          lines.each do |line|
            key, *rest = line.chomp.strip.split(":")
            value = rest.join(":").strip
            key = key.downcase.gsub(" ", "_")
            case key
            when "act", "acts"
              details[:acts] = value.split("|").map(&:strip)
            when "date", "gig_date", "gig_start_date"
              details[:date] = Date.parse(value)
            when "name", "gig_name"
              details[:name] = value
            when "price", "prices"
              details[:prices] = value.split("|").map(&:strip)
            when "tag", "tags"
              details[:tags] = value.split("|").map(&:strip)
            when "time", "gig_start_time"
              details[:time] = Time.parse(value)
            when "venue", "venue_name"
              details[:venue] = value
            when "url", "gig_url"
              details[:url] = value
            end
          end
        end
      end

      def append_prices(gig, prices)
        return unless prices.present?

        gig.prices.destroy_all
        prices.each do |price|
          amount, *remaining = price.split

          Lml::Price.create(
            gig: gig,
            amount: amount,
            description: remaining.join(" "),
          )
        end
      end

      def append_acts(gig, names)
        return unless names.present?

        acts = []
        gig.sets.destroy_all
        names.each do |name|
          act = Lml::Act.where("lower(name) = ?", name.downcase).first
          act ||= Lml::Act.create(name: name)
          Lml::Set.create(gig: gig, act: act)
          acts << act
        end
        gig.headline_act = acts.first
      end

      def append_date_time(gig, date, time)
        return unless date

        gig.date = date
        return unless time

        gig.start_time = "#{date.iso8601}T#{time.strftime("%H:%M")}:00"
        gig.start_offset_time = gig.start_time.strftime("%H:%M") if gig.start_time
      end
    end
  end
end
