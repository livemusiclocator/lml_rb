# frozen_string_literal: true

require "rails_helper"

# APIDOC.md is rendered through kramdown's GFM parser, which lives in a separate
# gem. It has to be a Gemfile entry of ours: as a transitive dependency of a
# development gem it is absent in production and the parse raises, which is
# exactly how this endpoint spent months returning a 500. See the Gemfile.
describe "docs" do
  describe "on api.lml.live" do
    before { host! "api.lml.live" }

    it "renders the api documentation" do
      get "/docs"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("<h2 id=\"endpoints\">Endpoints</h2>")
      expect(response.body).to include("https://api.lml.live")
    end
  end

  # Also served on www, because that is where the about section sends people
  # looking for it - see the api-stats-and-data page.
  describe "on www" do
    before { host! "www.livemusiclocator.com.au" }

    it "renders the api documentation" do
      get "/docs"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("<h2 id=\"endpoints\">Endpoints</h2>")
    end

    it "wears the web layout rather than the bare api one" do
      get "/docs"

      expect(response.body).to include("site-logo")
      expect(response.body).to include("<title>API Documentation - Live Music Locator</title>")
    end
  end
end
