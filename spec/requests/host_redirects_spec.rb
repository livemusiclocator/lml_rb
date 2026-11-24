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
    describe "short links" do
      before do
        host! "lml.live"
        @gig = create(:lml_gig)
      end

      it "sends a gig's short link to its page in the gig guide" do
        get URI(@gig.short_url).path

        expect(response).to have_http_status(:found)
        expect(response.headers["Location"]).to eq("http://www.livemusiclocator.com.au/gigs/#{@gig.id}")
      end

      it "sends a venue's and an act's short links to theirs" do
        act = create(:lml_act)

        get URI(@gig.venue.short_url).path
        expect(response.headers["Location"]).to eq("http://www.livemusiclocator.com.au/venues/#{@gig.venue.id}")

        get URI(act.short_url).path
        expect(response.headers["Location"]).to eq("http://www.livemusiclocator.com.au/acts/#{act.id}")
      end

      it "sends the long form the RSS feed links to as well" do
        get "/gigs/#{@gig.id}"

        expect(response).to have_http_status(:found)
        expect(response.headers["Location"]).to eq("http://www.livemusiclocator.com.au/gigs/#{@gig.id}")
      end

      it "is not found for a code nothing has" do
        get "/g/#{Lml::ShortLink.code(@gig.id).reverse}"

        expect(response).to have_http_status(:not_found)
      end

      it "lists every gig sharing a code" do
        first = create(:lml_gig, id: "3f9a2c1e-7b4d-4000-8000-000000000001", name: "First")
        create(:lml_gig, id: "3f9a2c1e-7b4d-4000-8000-000000000002", name: "Second")

        get URI(first.short_url).path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("First").and include("Second")
      end
    end

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
