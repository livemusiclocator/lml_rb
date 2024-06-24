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
          row(out, :url, gig.url) if gig.url.present?
          row(out, :series, gig.series)
          row(out, :category, gig.category)
          (gig.genre_tags || []).each { |tag| row(out, :genre, tag) }
          (gig.information_tags || []).each { |tag| row(out, :information, tag) }
          gig.sets.each { |set| row(out, :set, set.line) }
          gig.prices.each { |price| row(out, :price, price.line) }
        end

        out.string
      end

      private

      def row(io, heading, value)
        io.puts [heading, value].join(": ")
      end
    end
  end
end
