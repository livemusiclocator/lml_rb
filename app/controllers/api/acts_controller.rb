# frozen_string_literal: true

module Api
  # The public read API for acts. Deliberately its own controller rather than an
  # action on ActsController: that one is the admin only picker, and the html act
  # page will be Web::ActsController, so each host's acts endpoint has a
  # namespace of its own. Same shape is intended for venues.
  class ActsController < ApplicationController
    def show
      expires_in 10.minutes, public: true
      @act = Lml::Act.find(params[:id])
    end
  end
end
