# frozen_string_literal: true

class DocsController < ApplicationController
  def index
    doc_md = File.read(Rails.root.join("APIDOC.md"))
    @content = Kramdown::Document.new(doc_md, input: "GFM").to_html
  end
end
