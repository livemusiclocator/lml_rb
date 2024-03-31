module Lml
  module Processors
    class Clipper
      def initialize(upload)
        @upload = upload
      end

      def process!
        @upload.gig_ids = []
        details = {}

        @upload.content.lines.each do |line|
          key, *rest = line.chomp.strip.split(":")
          value = rest.join(":").strip
          key = key.downcase.gsub(" ", "_")
          case key
          when "acts"
            details[:act_names] = value.split("|").map(&:strip)
          when "venue_name"
            details[:venue_name] = value
          when "gig_name"
            details[:gig_name] = value
          when "gig_date", "gig_start_date"
            details[:date] = Date.parse(value)
          when "gig_start_time"
            details[:time] = Time.parse(value)
          end
        end

        gig = find_or_create_gig(details[:gig_name])
        append_acts(gig, details[:act_names])
        if @upload.venue
          gig.venue = @upload.venue
        else
          append_venue(gig, details[:venue_name])
        end
        append_date_time(gig, details[:date], details[:time])
        gig.save

        @upload.gig_ids << gig.id
        @upload.save!
      end

      private

      def find_or_create_gig(name)
        gig = Lml::Gig.where("lower(name) = ?", name.downcase).first
        gig || Lml::Gig.create(name: name)
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

      def append_venue(gig, name)
        return unless name

        gig.venue = Lml::Venue.where("lower(name) = ?", name.downcase).first
        gig.venue ||= Lml::Venue.create(name: name)

        return unless @upload.time_zone

        gig.venue.update!(
          location: @upload.time_zone,
          time_zone: @upload.time_zone,
        )
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
