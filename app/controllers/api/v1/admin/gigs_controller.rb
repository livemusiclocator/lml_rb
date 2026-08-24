# frozen_string_literal: true

module Api
  module V1
    module Admin
      # Read only. Gigs are written through uploads, because clipper is the
      # format the whole toolchain already speaks and a second write path would
      # be a second set of matching rules to keep in step.
      #
      # Deliberately NOT scoped to `visible`, unlike the public API and the
      # pickers. A caller comparing a venue's website against what we hold has
      # to see drafts and hidden gigs, or it re-adds a show that is already
      # sitting here unpublished.
      class GigsController < BaseController
        # Carries the parameter name so the message can say which date was
        # unreadable - "invalid date" on its own has sent people hunting.
        class BadDate < StandardError; end

        rescue_from BadDate, with: :bad_date

        def index
          scope = filtered_scope

          render json: {
            gigs: paginate(scope).map { |gig| serialize(gig) },
            meta: pagination_meta(scope),
          }
        end

        def show
          render json: { gig: serialize(Lml::Gig.eager.find(params[:id])) }
        end

        # The same clipper text the ActiveAdmin "Download Gigs" action produces,
        # so `gigs clipper` -> edit -> `uploads create` is a complete round trip.
        # Unpaginated on purpose: half a clipper file is not a clipper file.
        def clipper
          render plain: Lml::Processors::ClipperSerialiser.for_collection(filtered_scope)
        end

        private

        def bad_date(error)
          render_error(:bad_request, "Could not read #{error.message} as a date. Use YYYY-MM-DD.")
        end

        def filtered_scope
          scope = Lml::Gig.eager
          scope = scope.where(venue_id: params[:venue_id]) if params[:venue_id].present?
          scope = scope.where(date: date_from..) if date_from
          scope = scope.where(date: ..date_to) if date_to
          scope
        end

        # Upcoming by default. Every caller of this endpoint is asking "what have
        # we got coming up at this venue" - a listing that starts at the
        # beginning of time in date order would show them 2019. Pass date_from
        # explicitly to reach back.
        def date_from
          return Date.current unless params.key?(:date_from)

          parse_date(:date_from)
        end

        def date_to
          parse_date(:date_to)
        end

        # Date.iso8601 rather than Date.parse, which is far too generous to put
        # in front of a date range: Date.parse("next tuesdayish") is next
        # Tuesday, because it finds "tue" in there. A silently wrong window is
        # the one failure this endpoint exists to catch, so it must not be able
        # to cause it.
        def parse_date(key)
          value = params[key]
          return nil if value.blank?

          Date.iso8601(value)
        rescue Date::Error
          raise BadDate, key
        end

        def serialize(gig)
          gig.slice(:id, :name, :date, :status, :series, :category, :source)
             .merge(times(gig), tags(gig), associations(gig), state(gig), links(gig))
             .merge(created_at: gig.created_at, updated_at: gig.updated_at)
        end

        def times(gig)
          { start_time: gig.start_time, finish_time: gig.finish_time }
        end

        def state(gig)
          {
            ticket_status: gig.ticket_status,
            hidden: gig.hidden?,
            checked: gig.checked?,
            upload_id: gig.upload_id,
          }
        end

        def links(gig)
          {
            url: gig.url,
            ticketing_url: gig.ticketing_url,
            internal_description: gig.internal_description,
          }
        end

        # proposed_genre_tags is here as well as genre_tags because a caller
        # deciding whether a gig still needs work has to know the difference
        # between tags a human confirmed and tags OpenAI guessed at.
        def tags(gig)
          {
            genre_tags: gig.genre_tags || [],
            proposed_genre_tags: gig.proposed_genre_tags || [],
            information_tags: gig.information_tags || [],
          }
        end

        def associations(gig)
          {
            venue: gig.venue && { id: gig.venue.id, name: gig.venue.name },
            acts: gig.sets.map { |set| serialize_set(set) },
            prices: gig.prices.map { |price| { amount: price.amount.format, description: price.description } },
          }
        end

        def serialize_set(set)
          {
            id: set.act&.id,
            name: set.act&.name,
            start_time: set.start_time,
            finish_time: set.finish_time,
            stage: set.stage,
          }
        end
      end
    end
  end
end
