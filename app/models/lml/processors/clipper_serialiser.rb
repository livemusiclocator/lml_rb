# frozen_string_literal: true

module Lml
  module Processors
    module ClipperSerialiser
      def self.for_venue(venue)
        for_collection(venue.gigs.where(date: Date.yesterday..).eager)
      end

      def self.for_collection(gigs)
        out = StringIO.new
        gigs.each { |gig| serialise(out, gig) }
        out.string
      end

      def self.serialise(out, gig)
        out.puts "---"
        row(out, :id, gig.id)
        row(out, :name, gig.name)
        row(out, :venue_id, gig.venue_id)
        row(out, :date, gig.date&.iso8601)
        row(out, :start_time, gig.start_time)
        row(out, :finish_time, gig.finish_time)
        row(out, :status, gig.status)
        row(out, :tickets, gig.ticketing_url) if gig.ticketing_url.present?
        row(out, :url, gig.url) if gig.url.present?
        row(out, :series, gig.series)
        row(out, :category, gig.category)
        row(out, :internal_description, (gig.internal_description || "").lines.map(&:chomp).join(" "))
        (gig.genre_tags || []).each { |tag| row(out, :genre, tag) }
        (gig.information_tags || []).each { |tag| row(out, :information, tag) }
        gig.sets.each { |set| row(out, :set, set.line) }
        gig.prices.each { |price| row(out, :price, price.line) }
      end

      def self.row(out, heading, value)
        out.puts [heading, value].join(": ") unless value.blank?
      end
    end
  end
end
