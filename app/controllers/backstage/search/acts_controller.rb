# frozen_string_literal: true

module Backstage
  module Search
    class ActsController < Backstage::ApplicationController
      include PickerResults

      # The set list editor fills its act box with the act as a set line names
      # it, which is not the label - see Lml::Act#set_list_name.
      def index
        render_picker_results(Lml::Act.search(params[:q])) do |act|
          { set_list_name: act.set_list_name }
        end
      end
    end
  end
end
