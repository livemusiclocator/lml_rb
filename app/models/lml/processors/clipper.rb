# frozen_string_literal: true

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

          if details[:status] == "delete"
            gig.destroy
            next
          end

          append_prices(gig, details[:prices])
          gig.upload = @upload
          gig.status = details[:status] || "confirmed"
          gig.source = @upload.source
          gig.tags = details[:tags] if details[:tags].present?
          gig.ticketing_url = details[:ticketing_url] if details[:ticketing_url].present?
          append_sets(gig, details[:sets])
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
        return if prices.blank?

        gig.prices.destroy_all
        prices.each do |price|
          Lml::Price.create(price.merge(gig: gig))
        end
      end

      def append_sets(gig, sets)
        return if sets.blank?

        gig.sets.destroy_all
        sets.each do |set|
          act_name = set.delete(:act_name)
          act = Lml::Act.where("lower(name) = ?", act_name.downcase).first
          act ||= Lml::Act.create(name: act_name)
          Lml::Set.create(set.merge(gig: gig, act: act))
        end
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
