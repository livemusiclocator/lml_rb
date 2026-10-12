# frozen_string_literal: true

module Backstage
  # The venues a user has been allocated, and the gigs at each. Everything is
  # found through accessible_venues, so a venue somebody else manages is simply
  # not found rather than refused - unless the user is an admin, who can reach
  # them all.
  class VenuesController < ApplicationController
    PAST_GIG_LIMIT = 10
    OTHER_VENUE_LIMIT = 50

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

    private

    # The venue's own today, not the server's - a gig in Perth tonight is still
    # tonight there after midnight in Melbourne.
    def venue_today
      Time.current.in_time_zone(@venue.time_zone.presence || "UTC").to_date
    end
  end
end
