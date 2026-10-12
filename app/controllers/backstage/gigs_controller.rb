# frozen_string_literal: true

module Backstage
  # Gigs at the venues a user manages. Managing a venue is the authority to
  # change its gigs directly - the same rule ProposalsController applies - so
  # nothing here goes through review.
  class GigsController < ApplicationController
    def new
      @venue = managed_venue
      @gig = @venue.gigs.build(status: :confirmed)
    end

    def create
      @venue = managed_venue
      @gig = @venue.gigs.build

      if save_gig(@gig)
        redirect_to backstage_venue_path(@venue), notice: "Added #{@gig.name}."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @gig = managed_gig
      @venue = @gig.venue
    end

    def update
      @gig = managed_gig
      @venue = @gig.venue

      if save_gig(@gig)
        redirect_to backstage_venue_path(@venue), notice: "Saved #{@gig.name}."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def managed_venue
      current_user.managed_venues.find(params[:venue_id])
    end

    def managed_gig
      Lml::Gig.where(venue_id: current_user.managed_venues.select(:id)).find(params[:id])
    end

    def gig_params
      params.require(:gig).permit(
        :name,
        :date,
        :start_time,
        :finish_time,
        :status,
        :ticket_status,
        :ticketing_url,
        :description,
        :genre_tag_list,
        :set_list,
        :price_list,
      )
    end

    # Two orderings matter. finish_time is stored as a duration from the start,
    # so it has to be assigned after start_time. And assigning the set or price
    # list writes rows there and then, which needs a saved gig to point at, so
    # they go in only once the gig itself has saved.
    def save_gig(gig)
      attrs = gig_params.to_h
      lists = attrs.extract!("set_list", "price_list")
      finish_time = attrs.delete("finish_time")

      Lml::Gig.transaction do
        assign_gig_attributes(gig, attrs, finish_time)
        raise ActiveRecord::Rollback unless required_fields_present?(gig) && gig.save

        lists.each { |name, value| gig.public_send("#{name}=", value) }
        true
      end
    end

    def assign_gig_attributes(gig, attrs, finish_time)
      gig.assign_attributes(attrs)
      gig.finish_time = finish_time
    end

    # Imports create gigs with all sorts missing, so the model does not insist
    # on these. Somebody typing a gig in by hand has no excuse.
    def required_fields_present?(gig)
      gig.valid?
      gig.errors.add(:name, :blank) if gig.name.blank?
      gig.errors.add(:date, :blank) if gig.date.blank?
      gig.errors.empty?
    end
  end
end
