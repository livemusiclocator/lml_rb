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

    def render_custom_not_found
      render "web/shared/404", status: :not_found, layout: false
    end
  end
end
