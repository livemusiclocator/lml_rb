module Lml
  module Processors
    class Clipper
      def initialize(upload)
        @upload = upload
      end

      def process!
        venue = @upload.venue

        unless venue
          @upload.status = "Failed"
          @upload.error_description = "A venue is required"
          @upload.save!
          return
        end

        @upload.gig_ids = []

        entries = ClipperParser.extract_entries(@upload.content.lines)

        entries.each_with_index do |details, index|
          @upload.source = details[:url] if details[:url]

          unless details[:name].present? && details[:date].present?
            @upload.status = "Failed"
            @upload.error_description = "#{index + 1}: A date and gig name are required"
            @upload.save!
            return
          end

          gig = Lml::Gig.find_or_create_gig(
            name: details[:name],
            date: details[:date],
            venue: venue,
          )

          append_prices(gig, details[:prices])
          gig.status = :confirmed
          gig.tags = details[:tags] if details[:tags].present?
          gig.ticketing_url = details[:ticketing_url] if details[:ticketing_url].present?
          append_acts(gig, details[:acts])
          append_date_time(gig, details[:date], details[:time])
          gig.save
          @upload.status = "Succeeded"
          @upload.error_description = ""
          @upload.gig_ids << gig.id
        end

        @upload.save!
      end

      private

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
