#!/usr/bin/env ruby
# frozen_string_literal: true

module Web
  class MetaController < Web::ApplicationController
    # assumes id = 'sitemap' but should be able to extend this
    def show
      expires_in 1.days, public: true
      render file: "web/sitemap.xml", layout: false
    end
  end
end
