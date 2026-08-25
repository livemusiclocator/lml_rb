# frozen_string_literal: true

require "rails_helper"

# The routing spec cannot cover these: `route_to` does not recognise a redirect,
# which is why its "www redirects" examples are pending. A request spec can.
describe "host redirects" do
  # Printed on QR codes, so this one is out in the physical world and cannot be
  # changed or dropped - see the short_domain block at the bottom of routes.rb.
  #
  # The Location scheme follows the incoming request, so it is http here and
  # https in production, where config.force_ssl upgrades the request first.
  describe "lml.live" do
    it "sends the bare domain to the gig guide" do
      host! "lml.live"

      get "/"

      expect(response).to have_http_status(:moved_permanently)
      expect(response.headers["Location"])
        .to eq("http://www.livemusiclocator.com.au/?location=melbourne")
    end

    it "sends a location subdomain to that location" do
      host! "brisbane.lml.live"

      get "/"

      expect(response).to have_http_status(:moved_permanently)
      expect(response.headers["Location"])
        .to eq("http://www.livemusiclocator.com.au/?location=brisbane")
    end

    it "sends an edition subdomain to that edition" do
      host! "geelong.lml.live"

      get "/"

      expect(response).to have_http_status(:moved_permanently)
      expect(response.headers["Location"])
        .to eq("http://www.livemusiclocator.com.au/editions/geelong")
    end
  end

  # The api host used to redirect here too, because the redirect predates
  # subdomain constraints and caught every bare root. It answers now.
  describe "api.lml.live" do
    it "does not redirect to the gig guide" do
      host! "api.lml.live"

      get "/"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["documentation"]).to eq("http://api.lml.live/docs")
    end
  end
end
