# frozen_string_literal: true

module Backstage
  module Search
    class GigsController < Backstage::ApplicationController
      include PickerResults

      def index
        render_picker_results(Lml::Gig.search(params[:q], venue_id: params[:venue_id]))
      end
    end
  end
end
