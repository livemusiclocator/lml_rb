# frozen_string_literal: true

# The API documentation, rendered from APIDOC.md - the single source of truth,
# checked in next to the code so it moves in the same commit the API does.
#
# Served on api.lml.live, where the API is, and on www, where people actually go
# looking for it. It is the same document either way and only the chrome differs,
# so this is one controller picking a layout rather than the Api::/Web:: pair the
# json endpoints use.
class DocsController < ApplicationController
  layout :layout_for_host

  def index
    doc_md = File.read(Rails.root.join("APIDOC.md"))
    @content = Kramdown::Document.new(doc_md, input: "GFM").to_html
  end

  private

  # Matches the subdomain constraints in config/routes.rb. On www Rails reads the
  # whole "www.livemusiclocator" as the subdomain, so this asks the narrow
  # question - is this api.lml.live? - rather than trying to enumerate the rest.
  def layout_for_host
    request.subdomain == "api" ? "application" : "web/layouts/standalone_static"
  end
end
