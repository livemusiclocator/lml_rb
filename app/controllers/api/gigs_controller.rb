# frozen_string_literal: true

module Api
  # The gigs api on api.lml.live, also mounted at /api/gigs on www. Namespaced so
  # the json endpoints are not the same class as the html ones under Web:: - see
  # Api::ActsController.
  #
  # `search` is the admin only picker rather than public api, and belongs with
  # the acts and venues pickers rather than in here. Left where it was so this
  # stays a move and nothing else.
  class GigsController < ApplicationController
    include PickerResults
    include TokenAccess

    # Everything else here is public API; the picker is admin only.
    before_action :authenticate_admin_user!, only: :search

    # A signpost, not a hypermedia document. This used to return a HAL shaped
    # `links` object of pre-baked query urls: every one of them hardcoded to
    # location=castlemaine, and the `on_date` entry flagged `templated: true`
    # over an href that was not a uri template - a TODO admitted as much. No
    # client could traverse it and none tried. The documentation is the thing
    # people read, so point at it.
    #
    # request.base_url rather than a route helper because /docs is mounted under
    # two subdomain constraints and this action is mounted under both of them.
    def index
      @index = {
        name: "Live Music Locator API",
        documentation: "#{request.base_url}/docs",
        attribution: "Data courtesy of Live Music Locator: https://lml.live",
      }
    end

    def for
      expires_in 1.minutes, public: true

      location = params[:location] || "nowhere"
      date = Date.parse(params[:date] || "2000-01-01")

      venue_ids = Lml::Venue.where("lower(location) = ?", location).pluck(:id)

      @gigs = Lml::Gig.eager.visible.where(date: date, venue_id: venue_ids)

      render :query
    end

    def query
      expires_in 1.minutes, public: true

      location = params[:location] || "nowhere"
      date_from = Date.parse(params[:date_from] || "2000-01-01")
      date_to = Date.parse(params[:date_to] || "2000-01-01")

      date_to = date_from + 7.days if !token_authorized? && (date_to > date_from + 7.days)

      @gigs = Lml::Gig.eager.in_location(location).visible.where(date: (date_from..date_to))
    end

    def show
      @gig = Lml::Gig.find(params[:id])
    end

    def search
      render_picker_results(Lml::Gig.search(params[:q], venue_id: params[:venue_id]))
    end

    def feed
      date_from = Date.today
      date_to = date_from + 7.days
      @gigs = Lml::Gig.eager.visible.where(date: (date_from..date_to))

      respond_to do |format|
        format.rss { render layout: false }
      end
    end
  end
end
