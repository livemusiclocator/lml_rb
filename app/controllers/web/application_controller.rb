# frozen_string_literal: true

module Web
  class ApplicationController < ApplicationController
    layout "web/layouts/application"
    rescue_from ActiveRecord::RecordNotFound, with: :render_custom_not_found

    # The noun the 404 copy talks about. Set per controller, because the
    # controller is what knows: RecordNotFound only carries a model name when the
    # finder that raised it happened to know one, so reading it back off the
    # exception is a guess that fails quietly.
    class_attribute :not_found_subject, default: "gig"

    def metadata_source(model)
      # sets us some meta tags via the model's 'to_meta_tags' implementation
      set_meta_tags PageMetadataFactory.to_meta_tags(model)
      # save this to render as json ld
      @schema_source = PageMetadataFactory.to_json_ld(model)
    end

    private

    # Shared by every page that renders the spa shell, which needs an edition to
    # build window.APP_CONFIG from.
    def init_explorer_config
      @explorer_config =
        Web::ExplorerConfig.find_by_edition_id(params[:edition_id]) ||
        Web::ExplorerConfig.find_by_edition_id("main")
    end

    # TODO: should this go in the error controller instead? Not sure how.
    def render_custom_not_found
      @error_message_heading = "404"
      @error_message_sub_heading = "#{not_found_subject.capitalize} not found"
      @error_message_text =
        "We don't seem to have details about the #{not_found_subject} you are looking for."
      render "web/errors/404", status: :not_found, layout: "web/layouts/application"
    end
  end
end
