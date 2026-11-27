# frozen_string_literal: true

module Api
  module V1
    module Admin
      # Read only, and here so a caller can find the id to set a venue's
      # tourism_region_id to. Regions are reference data seeded on every deploy,
      # so they are changed in the seeds rather than through an api.
      class TourismRegionsController < BaseController
        def index
          scope = Web::TourismRegion.order(:name)

          render json: {
            tourism_regions: paginate(scope).map { |region| serialize(region) },
            meta: pagination_meta(scope),
          }
        end

        private

        def serialize(region)
          region.slice(:id, :internal_identifier, :name)
        end
      end
    end
  end
end
