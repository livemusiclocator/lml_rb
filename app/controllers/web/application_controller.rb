# frozen_string_literal: true

module Web
  class ApplicationController < ApplicationController
    layout "web/layouts/application"
    rescue_from ActiveRecord::RecordNotFound, with: :render_custom_not_found

    def metadata_source(model)
      # sets us some meta tags via the model's 'to_meta_tags' implementation
      set_meta_tags PageMetadataFactory.to_meta_tags(model)
      # save this to render as json ld
      @schema_source = PageMetadataFactory.to_json_ld(model)
    end

    private

    # TODO: should this go in the error controller instead? Not sure how.
    def render_custom_not_found
      @error_message_heading = "404"
      @error_message_sub_heading = "Gig not found"
      @error_message_text = "We don't seem to have details about the gig you are looking for."
      render "web/errors/404", status: :not_found, layout: "web/layouts/application"
    end
  end
end
