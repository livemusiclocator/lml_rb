# frozen_string_literal: true

module Web
  class PagesController < Web::ApplicationController
    rescue_from ActionController::RoutingError, with: :render_custom_not_found
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

    def page_finder
      page_info = helpers.about_section_static_page(params[:edition_id], params[:id])
      content_page_id = page_info&.dig(:content_page_id)
      unless content_page_id
        raise ActionController::RoutingError, "Not Found - page id #{params[:id]}, edition id #{params[:edition_id]} "
      end

      page_finder_factory.new(content_page_id)
    end

    def render_custom_not_found
      @error_message_heading = "404"
      @error_message_sub_heading = "Page not found"
      @error_message_text = "We don't seem to have details about the page you are looking for."
      render "web/errors/404", status: :not_found, layout: "web/layouts/application"
    end
  end
end
