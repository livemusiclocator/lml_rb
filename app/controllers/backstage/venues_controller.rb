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

    before_action :require_admin!, only: %i[new create]

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

    def new
      @venue = Lml::Venue.new(time_zone: "Australia/Melbourne")
    end

    def create
      @venue = Lml::Venue.new(venue_params)
      apply_google_place(@venue)

      if save_new_venue(@venue)
        redirect_to backstage_venue_path(@venue), notice: "Added #{@venue.name}."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @venue = accessible_venues.find(params[:id])
    end

    def update
      @venue = accessible_venues.find(params[:id])
      @venue.assign_attributes(venue_params)
      settle_google_place(@venue) if current_user.admin?

      if save_venue(@venue)
        redirect_to backstage_venue_path(@venue), notice: "Saved #{@venue.name}."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def venue_params
      params.require(:venue).permit(*EDITABLE_ATTRIBUTES)
    end

    # The Place Details response the form was filled from settles what
    # Lml::Place settles for any venue - its place id, address components,
    # business status and the whole response in google_place - and fills
    # anything the form left blank.
    def apply_google_place(venue)
      place = submitted_place or return

      venue.assign_attributes(place.attributes_for(venue))
    end

    # The edit form's refresh or search has already put Google's values in front of somebody, who
    # kept or rejected each one, so only what the place settles beyond those columns is taken here.
    # A place that is not this venue's own is ignored once the venue is resolved - it would only
    # overwrite the business status with somewhere else's.
    def settle_google_place(venue)
      place = submitted_place or return
      return if venue.address_components.present? && place.id != venue.google_place_id

      venue.assign_attributes(place.settled_for(venue))
    end

    def submitted_place
      payload = JSON.parse(params.dig(:venue, :google_place).presence || "null")
      payload.is_a?(Hash) ? Lml::Place.new(payload) : nil
    rescue JSON::ParserError
      nil
    end

    def save_venue(venue)
      taken = Lml::Venue.where.not(id: venue.id).exists?(google_place_id: venue.google_place_id)
      if venue.google_place_id_changed? && taken
        venue.errors.add(:base, "There is already a venue for that Google place")
        return false
      end
      venue.save
    end

    # Imports create venues with next to nothing, so the model does not insist
    # on a name. And one place should be one venue.
    def save_new_venue(venue)
      venue.validate
      venue.errors.add(:name, :blank) if venue.name.blank?
      if venue.google_place_id.present? && Lml::Venue.exists?(google_place_id: venue.google_place_id)
        venue.errors.add(:base, "There is already a venue for that Google place")
      end
      venue.errors.empty? && venue.save
    end

    # The venue's own today, not the server's - a gig in Perth tonight is still
    # tonight there after midnight in Melbourne.
    def venue_today
      Time.current.in_time_zone(@venue.time_zone.presence || "UTC").to_date
    end
  end
end
