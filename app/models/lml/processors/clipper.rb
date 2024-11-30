# frozen_string_literal: true

module Lml
  module Processors
    class Clipper
      def initialize(upload)
        @upload = upload
      end

      def process!
        default_venue = @upload.venue

        entries = ClipperParser.extract_entries(@upload.content.lines)

        entries.each_with_index do |details, index|
          venue = default_venue

          venue = Lml::Venue.find_by(id: details[:venue_id]) if details[:venue_id]

          unless venue
            @upload.status = "Failed"
            @upload.error_description = "#{index + 1}: A venue is required"
            @upload.save!
            return 1
          end

          Time.zone = venue.time_zone
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

          unless details[:start_time].blank?
            begin
              start_time = Time.parse(details[:start_time])
            rescue ArgumentError
              @upload.status = "Failed"
              @upload.error_description = "#{index + 1}: '#{details[:start_time]}' is not a valid time"
              @upload.save!
              return 1
            end
          end

          unless details[:finish_time].blank?
            begin
              finish_time = Time.parse(details[:finish_time])
            rescue ArgumentError
              @upload.status = "Failed"
              @upload.error_description = "#{index + 1}: '#{details[:finish_time]}' is not a valid time"
              @upload.save!
              return 1
            end
          end

          id = details[:id]
          weeks = details[:weeks] || 1

          weeks.times do |week_offset|
            if id.present?
              gig = Lml::Gig.find_by(id: id)
              unless gig
                @upload.status = "Failed"
                @upload.error_description = "#{index + 1}: A gig with id #{id} could not be found"
                @upload.save!
                return 1
              end
            end

            gig_date = date + (week_offset * 7)

            gig ||= Lml::Gig.find_or_create_gig(
              name: details[:name],
              date: gig_date,
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
            gig.date = gig_date
            gig.start_time = start_time.strftime("%H:%M") if start_time
            gig.duration = details[:duration]
            gig.finish_time = finish_time.strftime("%H:%M") if finish_time
            gig.save!
            gig.suggest_tags!
            @upload.status = "Succeeded"
            @upload.error_description = ""
          end
        end

        @upload.save!
      end
    end
  end
end
