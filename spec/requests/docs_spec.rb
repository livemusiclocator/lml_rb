# frozen_string_literal: true

require "rails_helper"

describe "docs" do
  before { host! "api.lml.live" }

  # This renders APIDOC.md through kramdown's GFM parser, which lives in a
  # separate gem. It has to be a Gemfile entry of ours: as a transitive
  # dependency of a development gem it is absent in production and the parse
  # raises. See the comment in the Gemfile.
  it "renders the api documentation" do
    get "/docs"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("<h1 id=\"live-music-locatior---api-documentation\">")
    expect(response.body).to include("https://api.lml.live")
  end
end
