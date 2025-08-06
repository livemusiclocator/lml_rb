#!/usr/bin/env ruby
# frozen_string_literal: true

module Web
  class MetaController < Web::ApplicationController
    # assumes id = 'sitemap' but should be able to extend this
    def show
      expires_in 1.days, public: true
      file_path = Rails.root.join("app/views/web/sitemap.xml")

      render file: file_path, layout: false, content_type: "application/xml"
    end
  end
end
