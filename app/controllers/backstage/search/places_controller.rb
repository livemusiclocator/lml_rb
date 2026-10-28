# frozen_string_literal: true

module Backstage
  module Search
    # Google Places suggestions for the new venue form, through our server so
    # the api key never reaches a browser. The session token ties these to the
    # details call for whichever place is picked, which makes them free.
    class PlacesController < Backstage::ApplicationController
      before_action :require_admin!

      def index
        response = Lml::GooglePlacesApiClient.new.autocomplete(
          params[:q].to_s,
          session_token: params[:session_token],
          region_code: Lml::VenuePlaceLookup::REGION_CODE,
          # Every venue we list is in Australia.
          restrict_to: [Lml::VenuePlaceLookup::REGION_CODE],
        )

        render json: suggestions(response)
      rescue Lml::GooglePlacesApiClient::Error => e
        Rails.logger.warn("places autocomplete failed: #{e.message}")
        render json: [], status: :bad_gateway
      end

      private

      # Query predictions ("bars near me") are not places, so they are left out.
      def suggestions(response)
        (response["suggestions"] || []).filter_map do |suggestion|
          prediction = suggestion["placePrediction"] or next

          { id: prediction["placeId"], label: prediction.dig("text", "text") }
        end
      end
    end
  end
end
