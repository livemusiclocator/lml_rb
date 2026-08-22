# frozen_string_literal: true

module Api
  module V1
    module Admin
      class ActsController < BaseController
        # No destroy: gigs point at acts through sets, and deleting one through
        # an API is not something we want to be one typo away from.
        WRITABLE = %i[
          name country location email website
          bandcamp facebook instagram linktree musicbrainz rym spotify wikipedia youtube
        ].freeze

        def index
          scope = params[:q].present? ? Lml::Act.search(params[:q]) : Lml::Act.order(:name)

          render json: {
            acts: paginate(scope).map { |act| serialize(act) },
            meta: pagination_meta(scope),
          }
        end

        def show
          render json: { act: serialize(Lml::Act.find(params[:id])) }
        end

        def create
          act = Lml::Act.new(act_params)
          return render_invalid(act) unless act.save

          render json: { act: serialize(act) }, status: :created
        end

        def update
          act = Lml::Act.find(params[:id])
          return render_invalid(act) unless act.update(act_params)

          render json: { act: serialize(act) }
        end

        private

        # An explicit allowlist rather than the model's full attribute set, so a
        # column we add later is not writable by accident.
        def act_params
          params.require(:act).permit(*WRITABLE, genres: [])
        end

        def serialize(act)
          act.slice(:id, :name, :country, :location, :email, :website)
             .merge(
               genres: act.genres || [],
               handles: act.slice(
                 :bandcamp, :facebook, :instagram, :linktree,
                 :musicbrainz, :rym, :spotify, :wikipedia, :youtube,
               ),
               created_at: act.created_at,
               updated_at: act.updated_at,
             )
        end
      end
    end
  end
end
