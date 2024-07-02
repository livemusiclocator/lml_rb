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

        Time.zone = venue.time_zone

        entries = ClipperParser.extract_entries(@upload.content.lines)

        entries.each_with_index do |details, index|
          unless details[:name].present?
            @upload.status = "Failed"
            @upload.error_description = "#{index + 1}: A gig name is required"
            @upload.save!
            return 1
          end

          begin
            date = Date.parse(details[:date] || "")
          rescue Date::Error
            @upload.status = "Failed"
            @upload.error_description = "#{index + 1}: '#{details[:date]}' is not a valid date"
            @upload.save!
            return 1
          end

          unless details[:time].blank?
            begin
              time = Time.parse(details[:time])
            rescue ArgumentError
              @upload.status = "Failed"
              @upload.error_description = "#{index + 1}: '#{details[:time]}' is not a valid time"
              @upload.save!
              return 1
            end
          end

          id = details[:id]
          if id.present?
            gig = Lml::Gig.find_by(id: id)
            unless gig
              @upload.status = "Failed"
              @upload.error_description = "#{index + 1}: A gig with id #{id} could not be found"
              @upload.save!
              return 1
            end
          end

          gig ||= Lml::Gig.find_or_create_gig(
            name: details[:name],
            date: date,
            venue: venue,
          )

          if details[:status] == "delete"
            gig.destroy
            next
          end

          gig.name = details[:name]
          gig.venue = venue
          gig.upload = @upload
          gig.status = details[:status] || "confirmed"
          gig.internal_description = details[:internal_description]
          gig.source = @upload.source
          gig.url = details[:url]
          gig.information_tags = details[:information_tags] if details[:information_tags].present?
          gig.genre_tags = details[:genre_tags] if details[:genre_tags].present?
          gig.series = details[:series]
          gig.category = details[:category]
          gig.ticketing_url = details[:ticketing_url] if details[:ticketing_url].present?
          gig.set_list = details[:sets].join("\n") if details[:sets].present?
          gig.price_list = details[:prices].join("\n") if details[:prices].present?
          append_date_time(gig, date, time)
          gig.save!
          gig.suggest_tags!
          @upload.status = "Succeeded"
          @upload.error_description = ""
        end

        @upload.save!
      end

      private

      def append_date_time(gig, date, time)
        gig.date = date
        return if time.blank?

        gig.start_time = "#{date.iso8601}T#{time.strftime("%H:%M")}:00"
        gig.start_offset_time = gig.start_time.strftime("%H:%M") if gig.start_time
      end
    end
  end
end
