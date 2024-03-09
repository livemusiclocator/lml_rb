# frozen_string_literal: true

class VenuesController < ApplicationController
  def autocomplete
    @venues = Lml::Venue.order(:name)
  end
end
