# frozen_string_literal: true

module Backstage
  # Folds a duplicate into the venue being looked at: its gigs and managers move across, gaps are
  # filled from it, what it knew differently goes into the notes, and then it is deleted. See
  # Lml::VenueMerge.
  class VenueMergesController < ApplicationController
    before_action :require_admin!

    def create
      venue = Lml::Venue.find(params[:venue_id])
      duplicate = Lml::Venue.find_by(id: params[:duplicate_id])
      return redirect_to backstage_venue_path(venue), alert: "Pick a venue to merge in first." unless duplicate

      result = Lml::VenueMerge.new(survivor: venue, duplicate: duplicate).call
      redirect_to backstage_venue_path(venue), notice: merged_notice(duplicate, venue, result)
    rescue Lml::VenueMerge::Error, ActiveRecord::RecordInvalid => e
      # One transaction, so there is nothing half done to explain.
      redirect_to backstage_venue_path(venue), alert: "Nothing was merged: #{e.message}"
    end

    private

    def merged_notice(duplicate, venue, result)
      ["Merged #{duplicate.name} into #{venue.name}.", result.summary.presence].compact.join(" ")
    end
  end
end
