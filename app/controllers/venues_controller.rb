# frozen_string_literal: true

class VenuesController < ApplicationController
  def autocomplete
    @venues = Lml::Venue.order(:name)
  end

  def search
    q = params[:q].to_s.strip
    venues = Lml::Venue.order(:name)
    venues = venues.where("LOWER(name) LIKE LOWER(?)", "%#{q}%") if q.present?
    @venues = venues.limit(10)
  end
end
