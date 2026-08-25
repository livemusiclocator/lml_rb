# frozen_string_literal: true

module Web
  # The html act page, matching the spa's client side /acts/:id route. Its
  # opposite number is Api::ActsController, which serves the json the page then
  # asks for - one namespace per host rather than one class answering to both.
  class ActsController < Web::ApplicationController
    layout "web/layouts/explorer"
    before_action :init_explorer_config

    self.not_found_subject = "act"

    def show
      expires_in 10.minutes, public: true
      @act = Lml::Act.find(params[:id])
      metadata_source @act
      render
    end
  end
end
