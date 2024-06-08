# frozen_string_literal: true

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
          row(out, :id, gig.id)
          row(out, :name, gig.name)
          row(out, :date, gig.date.iso8601)
          row(out, :time, gig.start_offset_time)
          row(out, :status, gig.status)
          row(out, :tickets, gig.ticketing_url) if gig.ticketing_url.present?
          gig.sets.each { |set| row(out, :set, build_set(set)) }
          gig.prices.each { |price| row(out, :price, build_price(price)) }
          (gig.tags || []).each { |tag| write_tag(out, tag) }
        end

        out.string
      end

      private

      def build_set(set)
        act = set.act.name
        if set.act.location
          act = if set.act.country
                  "#{act} (#{set.act.location}/#{set.act.country})"
                else
                  "#{act} (#{set.act.location}/Australia)"
                end
        end
        "#{act}|#{set.start_offset_time}|#{set.duration}|#{set.stage}"
      end

      def build_price(price)
        "#{price.amount.format} #{price.description}"
      end

      def write_tag(out, value)
        prefix, *rest = value.split(":")
        row(out, prefix, rest.join(":"))
      end

      def row(io, heading, value)
        io.puts [heading, value].join(": ")
      end
    end
  end
end
