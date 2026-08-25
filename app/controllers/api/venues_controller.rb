# frozen_string_literal: true

module Api
  # The public read api for venues. Its own controller rather than an action on
  # VenuesController, which is the admin picker and the token gated autocomplete
  # - see Api::ActsController for the same split.
  class VenuesController < ApplicationController
    def show
      expires_in 10.minutes, public: true
      @venue = Lml::Venue.find(params[:id])
    end
  end
end
