# frozen_string_literal: true

module Backstage
  # Everything Google Places has on the place picked in the new venue form: the
  # fields to fill in, and the whole response for the form to send back so it
  # is kept on the venue. Every call here is billable, which is why it is only
  # made for a place somebody has chosen.
  class PlacesController < ApplicationController
    before_action :require_admin!

    def show
      payload = Lml::GooglePlacesApiClient.new.details(params[:id], session_token: params[:session_token])

      render json: {
        attributes: Lml::Place.new(payload).form_attributes,
        place: payload,
        existing: existing_venue(payload["id"]),
      }
    rescue Lml::GooglePlacesApiClient::Error => e
      Rails.logger.warn("places details failed: #{e.message}")
      render json: { error: "Google Places did not answer. Try again, or fill the venue in by hand." },
        status: :bad_gateway
    end

    private

    # One place should be one venue, so say so before somebody adds it twice.
    def existing_venue(place_id)
      venue = Lml::Venue.find_by(google_place_id: place_id)
      venue && { name: venue.name, url: backstage_venue_path(venue) }
    end
  end
end
