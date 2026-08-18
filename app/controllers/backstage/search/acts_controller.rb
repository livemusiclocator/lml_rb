# frozen_string_literal: true

module Backstage
  module Search
    class ActsController < Backstage::ApplicationController
      include PickerResults

      def index
        render_picker_results(Lml::Act.search(params[:q]))
      end
    end
  end
end
