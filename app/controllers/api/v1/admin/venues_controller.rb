# frozen_string_literal: true

module Api
  module V1
    module Admin
      class VenuesController < BaseController
        # No destroy: a venue owns its gigs with `dependent: :delete_all`, so one
        # DELETE would quietly take a venue's whole history with it.
        #
        # google_place_id, address_components and google_business_status are
        # deliberately absent - those are resolved from Google (see Lml::Place)
        # and a caller writing them by hand would silently break address matching.
        WRITABLE = %i[
          name location address time_zone capacity vibe notes lga
          email phone postcode website location_url facebook_url instagram_url
          latitude longitude
        ].freeze

        def index
          scope = params[:q].present? ? Lml::Venue.search(params[:q]) : Lml::Venue.order(:name)

          render json: {
            venues: paginate(scope).map { |venue| serialize(venue) },
            meta: pagination_meta(scope),
          }
        end

        def show
          render json: { venue: serialize(Lml::Venue.find(params[:id])) }
        end

        def create
          venue = Lml::Venue.new(venue_params)
          return render_invalid(venue) unless venue.save

          render json: { venue: serialize(venue) }, status: :created
        end

        def update
          venue = Lml::Venue.find(params[:id])
          return render_invalid(venue) unless venue.update(venue_params)

          render json: { venue: serialize(venue) }
        end

        private

        # An explicit allowlist rather than the model's full attribute set, so a
        # column we add later is not writable by accident.
        def venue_params
          params.require(:venue).permit(*WRITABLE, tags: [])
        end

        def serialize(venue)
          venue.slice(*WRITABLE, :id)
               .merge(
                 tags: venue.tags || [],
                 google_place_id: venue.google_place_id,
                 google_business_status: venue.google_business_status,
                 created_at: venue.created_at,
                 updated_at: venue.updated_at,
               )
        end
      end
    end
  end
end
