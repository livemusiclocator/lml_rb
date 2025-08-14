# frozen_string_literal: true

module Web
  class ExplorerController < Web::ApplicationController
    layout "web/layouts/explorer"
    before_action :init_explorer_config

    def index
      expires_in 10.minutes, public: true

      search = Web::GigSearch.new(search_params)
      if search.valid?
        metadata_source search
      else
        metadata_source Web::GigSearch.new
      end
      render
    end

    def show
      expires_in 10.minutes, public: true
      @gig = Lml::Gig.find(params[:id])
      metadata_source @gig
      render
    end

    def search_params
      # expected parameters - stops warnings in the logs

      params.transform_keys(&:underscore)
            .permit(:location, :date_range, :custom_date, :edition_id, :venues, genre: [])
            .slice(:location, :date_range, :custom_date, :genre)
    end

    private

    def init_explorer_config
      @explorer_config = Web::ExplorerConfig.find_by_edition_id(params[:edition_id]) ||  Web::ExplorerConfig.find_by_edition_id("main")
    end
  end
end
