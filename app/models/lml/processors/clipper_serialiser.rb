module Lml
  module Processors
    class ClipperSerialiser
      def initialize(venue)
        @venue = venue
      end

      def serialise
        out = StringIO.new

        @venue.gigs.eager.each do |gig|
          out.puts "---"
          row(out, :name, gig.name)
          row(out, :date, gig.date.iso8601)
          row(out, :time, gig.start_offset_time)
          row(out, :status, gig.status)
          row(out, :acts, acts(gig)) if gig.sets.count > 0
          row(out, :prices, prices(gig)) if gig.prices.count > 0
          row(out, :tags, tags(gig)) if gig.tags.present? && gig.tags.count > 0
          row(out, :tickets, gig.ticketing_url) if gig.ticketing_url.present?
        end

        out.string
      end

      private

      def acts(gig)
        gig.sets.map { |set| set.act.name }.join(" | ")
      end

      def prices(gig)
        gig.prices.map { |price| [price.amount.format, price.description].join(" ") }.join(" | ")
      end

      def tags(gig)
        gig.tags.join(" | ")
      end

      def row(io, heading, value)
        io.puts [heading, value].join(": ")
      end
    end
  end
end
