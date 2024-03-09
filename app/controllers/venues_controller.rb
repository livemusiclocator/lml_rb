# frozen_string_literal: true

class VenuesController < ApplicationController
  def query
    @venues = Lml::Venue.order(:name)
  end
end
