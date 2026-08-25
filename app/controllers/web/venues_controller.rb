# frozen_string_literal: true

module Web
  # The html venue page, the act page's opposite number - see Web::ActsController.
  # Api::VenuesController serves the json the spa then asks for.
  class VenuesController < Web::ApplicationController
    layout "web/layouts/explorer"
    before_action :init_explorer_config

    self.not_found_subject = "venue"

    def show
      expires_in 10.minutes, public: true
      @venue = Lml::Venue.find(params[:id])
      metadata_source @venue
      render
    end
  end
end
