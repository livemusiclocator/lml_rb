# frozen_string_literal: true

module Backstage
  module Search
    class VenuesController < Backstage::ApplicationController
      include PickerResults

      def index
        render_picker_results(Lml::Venue.search(params[:q]))
      end
    end
  end
end
