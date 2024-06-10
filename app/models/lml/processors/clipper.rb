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

        @upload.gig_ids = []

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

          append_prices(gig, details[:prices])
          gig.name = details[:name]
          gig.venue = venue
          gig.upload = @upload
          gig.status = details[:status] || "confirmed"
          gig.source = @upload.source
          gig.tags = details[:tags] if details[:tags].present?
          gig.ticketing_url = details[:ticketing_url] if details[:ticketing_url].present?
          append_sets(gig, details[:sets])
          append_date_time(gig, date, time)
          gig.save
          @upload.source = details[:url] if details[:url]
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
          act = find_or_create_act(set.delete(:act_name))
          Lml::Set.create(set.merge(gig: gig, act: act))
        end
      end

      def find_or_create_act(details)
        name, location, country = extract_name_location_country(details)
        act = Lml::Act.where("lower(name) = ?", name.downcase).first
        if act
          act.update!(location: location, country: country)
          act
        else
          Lml::Act.create(name: name, location: location, country: country)
        end
      end

      def extract_name_location_country(details)
        match = /(.*) \((.*)\)/.match(details)
        return details unless match

        name = match[1].strip
        location = match[2].strip
        match = %r{(.*)/(.*)}.match(location)

        return [name, location, "Australia"] unless match

        [name, match[1], match[2]]
      end

      def append_date_time(gig, date, time)
        gig.date = date
        return if time.blank?

        gig.start_time = "#{date.iso8601}T#{time.strftime("%H:%M")}:00"
        gig.start_offset_time = gig.start_time.strftime("%H:%M") if gig.start_time
      end
    end
  end
end
