# frozen_string_literal: true

module Lml
  module Processors
    # One clipper entry applied to the gigs it describes. Shared by the upload
    # forms (Processors::Clipper, which stops at the first entry that fails)
    # and the admin API's bulk update (Lml::GigBulkUpdate, which carries on).
    class ClipperEntry
      class Failed < StandardError
        attr_reader :result

        def initialize(message, result: "invalid")
          @result = result
          super(message)
        end
      end

      CREATED = "created"
      UPDATED = "updated"
      DELETED = "deleted"

      # result is created, updated or deleted - created if any gig was new.
      # gig_ids is every gig the entry ended up as, several for `weeks`.
      Outcome = Struct.new(:result, :gig_ids, keyword_init: true)

      def initialize(details, default_venue:, source:, upload: nil, uploaded_by: nil)
        @details = details
        @default_venue = default_venue
        @source = source
        @upload = upload
        @uploaded_by = uploaded_by
      end

      # Raises Failed, before anything is written, for an entry that cannot be
      # read - except a missing gig id in a later week of `weeks`, which is
      # found only once the earlier weeks are saved, as it always was.
      def apply!
        venue = find_venue
        Time.zone = venue.time_zone
        raise Failed, "A gig name is required" if @details[:name].blank?

        date = parse_date
        start_time = parse_time(@details[:start_time])
        finish_time = parse_time(@details[:finish_time])

        outcomes = weeks.times.map do |week_offset|
          apply_week(venue, date + (week_offset * 7), start_time, finish_time)
        end
        Outcome.new(result: summarise(outcomes.map(&:first)), gig_ids: outcomes.filter_map(&:last))
      end

      private

      def find_venue
        venue = @details[:venue_id] ? Lml::Venue.find_by(id: @details[:venue_id]) : @default_venue
        venue || raise(Failed, "A venue is required")
      end

      def weeks
        @details[:weeks] || 1
      end

      def parse_date
        Date.parse(@details[:date] || "")
      rescue Date::Error
        raise Failed, "'#{@details[:date]}' is not a valid date"
      end

      def parse_time(value)
        return if value.blank?

        Time.parse(value)
      rescue ArgumentError
        raise Failed, "'#{value}' is not a valid time"
      end

      def find_gig(venue, gig_date)
        if @details[:id].present?
          return Lml::Gig.find_by(id: @details[:id]) ||
              raise(Failed.new("A gig with id #{@details[:id]} could not be found", result: "not_found"))
        end

        Lml::Gig.find_or_create_gig(name: @details[:name], date: gig_date, venue: venue)
      end

      def apply_week(venue, gig_date, start_time, finish_time)
        gig = find_gig(venue, gig_date)
        created = gig.previously_new_record?

        if @details[:status] == "delete"
          gig.destroy
          return [DELETED, nil]
        end

        assign(gig, venue, gig_date, start_time, finish_time)
        gig.save!
        gig.suggest_tags! unless ENV["DISABLE_CLIPPER_TAG_SUGGESTION"]
        [created ? CREATED : UPDATED, gig.id]
      end

      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      def assign(gig, venue, gig_date, start_time, finish_time)
        details = @details
        gig.name = details[:name]
        gig.venue = venue
        gig.upload = @upload
        gig.uploaded_by = @uploaded_by if @uploaded_by
        gig.status = details[:status] || "confirmed"
        gig.internal_description = details[:internal_description]
        gig.source = @source
        gig.url = details[:url]
        gig.information_tags = details[:information_tags] if details[:information_tags].present?
        gig.genre_tags = details[:genre_tags] if details[:genre_tags].present?
        gig.proposed_acts = details[:proposed_acts] if details[:proposed_acts].present?
        gig.series = details[:series]
        gig.category = details[:category]
        gig.ticketing_url = details[:ticketing_url] if details[:ticketing_url].present?
        gig.set_list = details[:sets].join("\n") if details[:sets].present?
        gig.price_list = details[:prices].join("\n") if details[:prices].present?
        gig.date = gig_date
        gig.start_time = start_time.strftime("%H:%M") if start_time
        gig.duration = details[:duration]
        gig.finish_time = finish_time.strftime("%H:%M") if finish_time
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

      def summarise(results)
        return CREATED if results.include?(CREATED)
        return UPDATED if results.include?(UPDATED)

        DELETED
      end
    end
  end
end
