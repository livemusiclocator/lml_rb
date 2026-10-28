# frozen_string_literal: true

module Backstage
  # The venues a user has been allocated, their details and the gigs at each. Everything is
  # found through accessible_venues, so a venue somebody else manages is simply
  # not found rather than refused - unless the user is an admin, who can reach
  # them all.
  class VenuesController < ApplicationController
    PAST_GIG_LIMIT = 10
    OTHER_VENUE_LIMIT = 50
    # What ActiveAdmin's venue form edits, less the admin user it is assigned to.
    EDITABLE_ATTRIBUTES = %i[
      name
      time_zone
      location
      address
      postcode
      lga
      lat_lng
      capacity
      vibe
      tag_list
      email
      phone
      website
      instagram_url
      facebook_url
      location_url
      notes
    ].freeze

    def index
      @venues = current_user.managed_venues.order(:name)
      return unless current_user.admin?

      @query = params[:q].to_s.strip
      others = Lml::Venue.search(@query).where.not(id: @venues.select(:id))
      @other_venue_count = others.count
      @other_venues = others.limit(OTHER_VENUE_LIMIT)
    end

    def show
      @venue = accessible_venues.find(params[:id])
      today = venue_today
      gigs = @venue.gigs.includes(sets: :act)
      @upcoming = gigs.where(date: today..).order(:date, :start_offset)
      @past = gigs.where(date: ...today).order(date: :desc, start_offset: :desc).limit(PAST_GIG_LIMIT)
    end

    def edit
      @venue = accessible_venues.find(params[:id])
    end

    def update
      @venue = accessible_venues.find(params[:id])

      if @venue.update(venue_params)
        redirect_to backstage_venue_path(@venue), notice: "Saved #{@venue.name}."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def venue_params
      params.require(:venue).permit(*EDITABLE_ATTRIBUTES)
    end

    # The venue's own today, not the server's - a gig in Perth tonight is still
    # tonight there after midnight in Melbourne.
    def venue_today
      Time.current.in_time_zone(@venue.time_zone.presence || "UTC").to_date
    end
  end
end
