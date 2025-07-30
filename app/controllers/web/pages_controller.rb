# frozen_string_literal: true

module Web
  class PagesController < Web::ApplicationController
    include HighVoltage::StaticPage

    layout :layout_for_page
    def layout_for_page
      case params[:section]
      when "about"
        "web/layouts/about"
      else
        "web/layouts/standalone_static"
      end
    end
  end
end
