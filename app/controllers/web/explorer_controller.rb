# frozen_string_literal: true

module Web
  class ExplorerController < Web::ApplicationController
    layout "web/layouts/explorer"
    def index
      search = Web::GigSearch.new(search_params)
      if search.valid?
        metadata_source search
      else
        metadata_source Web::GigSearch.new
      end
      render
    end

    def show
      @gig = Lml::Gig.find(params[:id])
      metadata_source @gig
      render
    end

    def search_params
      params.transform_keys(&:underscore).permit(:location, :date_range, :custom_date, genre: [])
    end
  end
end
