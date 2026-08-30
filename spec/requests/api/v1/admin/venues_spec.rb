# frozen_string_literal: true

require "rails_helper"

describe "admin api venues" do
  before do
    host! "api.lml.live"

    @admin = create(:lml_user, :admin)
    @headers = { "Authorization" => "Bearer #{Lml::ApiToken.issue!(user: @admin, name: "Import").plaintext}" }

    @tote = create(:lml_venue, name: "The Tote", location: "melbourne")
    @bridge = create(:lml_venue, name: "Bridge Hotel", location: "castlemaine")
  end

  def body
    JSON.parse(response.body)
  end

  describe "listing" do
    it "returns venues in name order with pagination metadata" do
      get "/v1/admin/venues", headers: @headers

      expect(body["venues"].map { |v| v["name"] }).to eq(["Bridge Hotel", "The Tote"])
      expect(body["meta"]).to eq({ "page" => 1, "per_page" => 50, "total" => 2 })
    end

    it "pages through the collection" do
      get "/v1/admin/venues", params: { per_page: 1, page: 2 }, headers: @headers

      expect(body["venues"].map { |v| v["name"] }).to eq(["The Tote"])
    end

    it "refuses to dump more than a hundred at a time however much is asked for" do
      get "/v1/admin/venues", params: { per_page: 5000 }, headers: @headers

      expect(body["meta"]["per_page"]).to eq(100)
    end

    it "searches by name" do
      get "/v1/admin/venues", params: { q: "tote" }, headers: @headers

      expect(body["venues"].map { |v| v["name"] }).to eq(["The Tote"])
    end
  end

  describe "showing" do
    it "returns the venue" do
      get "/v1/admin/venues/#{@tote.id}", headers: @headers

      expect(body["venue"]).to include("id" => @tote.id, "name" => "The Tote", "location" => "melbourne")
    end

    it "returns the local government area, which is not derivable from location" do
      @tote.update!(lga: "City of Yarra")

      get "/v1/admin/venues/#{@tote.id}", headers: @headers

      expect(body["venue"]).to include("lga" => "City of Yarra")
    end

    it "returns a json 404 for a venue that does not exist" do
      get "/v1/admin/venues/#{SecureRandom.uuid}", headers: @headers

      expect(response).to have_http_status(:not_found)
      expect(body["error"]).to be_present
    end
  end

  describe "creating" do
    it "creates a venue" do
      post "/v1/admin/venues", headers: @headers, params: {
        venue: { name: "The Curtin", location: "melbourne", time_zone: "Australia/Melbourne", capacity: 200 },
      }

      expect(response).to have_http_status(:created)
      expect(Lml::Venue.find(body["venue"]["id"]).name).to eq("The Curtin")
    end

    it "sets the local government area" do
      post "/v1/admin/venues", headers: @headers, params: {
        venue: { name: "The Curtin", time_zone: "Australia/Melbourne", lga: "City of Melbourne" },
      }

      expect(Lml::Venue.find(body["venue"]["id"]).lga).to eq("City of Melbourne")
    end

    it "reports validation failures rather than saving half a venue" do
      post "/v1/admin/venues", headers: @headers, params: {
        venue: { name: "Nowhere", time_zone: "Mars/Olympus_Mons" },
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(body["details"]).to include("time_zone")
    end

    it "asks for the venue key rather than guessing" do
      post "/v1/admin/venues", headers: @headers, params: { name: "The Curtin" }

      expect(response).to have_http_status(:bad_request)
    end

    it "ignores attributes we resolve from google rather than letting a caller set them" do
      post "/v1/admin/venues", headers: @headers, params: {
        venue: {
          name: "The Curtin", time_zone: "Australia/Melbourne",
          google_place_id: "forged", address_components: { route: "Fake Street" },
        },
      }

      expect(Lml::Venue.find(body["venue"]["id"]).google_place_id).to be_nil
    end
  end

  describe "updating" do
    it "updates the venue" do
      patch "/v1/admin/venues/#{@tote.id}", headers: @headers, params: { venue: { capacity: 350 } }

      expect(@tote.reload.capacity).to eq(350)
    end

    it "leaves attributes it was not given alone" do
      patch "/v1/admin/venues/#{@tote.id}", headers: @headers, params: { venue: { capacity: 350 } }

      expect(@tote.reload.name).to eq("The Tote")
    end

    it "corrects the local government area" do
      @tote.update!(lga: "City of Melbourne")

      patch "/v1/admin/venues/#{@tote.id}", headers: @headers, params: { venue: { lga: "City of Yarra" } }

      expect(@tote.reload.lga).to eq("City of Yarra")
    end

    it "reports validation failures without changing the venue" do
      patch "/v1/admin/venues/#{@tote.id}", headers: @headers, params: {
        venue: { name: "Renamed", time_zone: "Mars/Olympus_Mons" },
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(@tote.reload.name).to eq("The Tote")
    end

    it "refuses to repoint a venue's google place" do
      patch "/v1/admin/venues/#{@tote.id}", headers: @headers, params: {
        venue: { google_place_id: "forged" },
      }

      expect(@tote.reload.google_place_id).to be_nil
    end
  end

  describe "looking a venue up in google places" do
    def places_returning(*places)
      stub_request(:post, Lml::GooglePlacesApiClient::FIND_URL)
        .to_return(status: 200, body: { places: places }.to_json, headers: { "Content-Type" => "application/json" })
    end

    def espy_place(id: "placeespy")
      {
        id: id,
        displayName: { text: "Hotel Esplanade" },
        formattedAddress: "11 The Esplanade, St Kilda VIC 3182",
        businessStatus: "OPERATIONAL",
        location: { latitude: -37.8676, longitude: 144.9756 },
        addressComponents: [{ types: ["route"], shortText: "The Esplanade", longText: "The Esplanade" }],
      }
    end

    it "resolves a venue and reports what it settled on" do
      places_returning(espy_place)

      post "/v1/admin/venues/#{@tote.id}/place_lookup", headers: @headers

      expect(body["outcome"]).to eq("matched")
      expect(body["venue"]["google_place_id"]).to eq("placeespy")
    end

    it "fills in a blank column from google" do
      places_returning(espy_place)

      post "/v1/admin/venues/#{@tote.id}/place_lookup", headers: @headers

      expect(@tote.reload.latitude).to eq(-37.8676)
    end

    it "leaves a column that already has a value alone" do
      @tote.update!(latitude: -37.0, longitude: 144.0)
      places_returning(espy_place)

      post "/v1/admin/venues/#{@tote.id}/place_lookup", headers: @headers

      expect(@tote.reload.latitude).to eq(-37.0)
    end

    it "hands back a maps link built from the place id" do
      places_returning(espy_place)

      post "/v1/admin/venues/#{@tote.id}/place_lookup", headers: @headers

      expect(body["venue"]["google_maps_url"]).to include("query_place_id=placeespy")
    end

    it "leaves location_url to mean the link a person chose" do
      @tote.update!(location_url: "https://maps.app.goo.gl/shortlink")
      places_returning(espy_place)

      post "/v1/admin/venues/#{@tote.id}/place_lookup", headers: @headers

      expect(body["venue"]["location_url"]).to eq("https://maps.app.goo.gl/shortlink")
    end

    it "has no maps link for a venue it could not settle" do
      places_returning

      post "/v1/admin/venues/#{@tote.id}/place_lookup", headers: @headers

      expect(body["venue"]["google_maps_url"]).to be_nil
    end

    it "records a marker when google has nothing, rather than looking like it never ran" do
      places_returning

      post "/v1/admin/venues/#{@tote.id}/place_lookup", headers: @headers

      expect(body["outcome"]).to eq("no_match")
      expect(@tote.reload.google_place_id).to eq("no match")
    end

    it "records a marker when google offers a choice" do
      places_returning(espy_place(id: "one"), espy_place(id: "two"))

      post "/v1/admin/venues/#{@tote.id}/place_lookup", headers: @headers

      expect(body["outcome"]).to eq("ambiguous")
      expect(@tote.reload.google_place_id).to eq("ambiguous - 2 matches")
    end

    it "spends nothing on a venue that has already been asked about" do
      @tote.update!(google_place_id: "no match")
      request = places_returning(espy_place)

      post "/v1/admin/venues/#{@tote.id}/place_lookup", headers: @headers

      expect(body["outcome"]).to eq("skipped")
      expect(request).not_to have_been_requested
    end

    it "asks again when forced" do
      @tote.update!(google_place_id: "no match")
      places_returning(espy_place)

      post "/v1/admin/venues/#{@tote.id}/place_lookup", params: { force: true }, headers: @headers

      expect(body["outcome"]).to eq("matched")
      expect(@tote.reload.google_place_id).to eq("placeespy")
    end

    it "reads force as the string a form or curl would send it as" do
      @tote.update!(google_place_id: "no match")
      places_returning(espy_place)

      post "/v1/admin/venues/#{@tote.id}/place_lookup", params: { force: "true" }, headers: @headers

      expect(body["outcome"]).to eq("matched")
    end

    it "does not treat force=false as a reason to spend" do
      @tote.update!(google_place_id: "no match")
      places_returning(espy_place)

      post "/v1/admin/venues/#{@tote.id}/place_lookup", params: { force: "false" }, headers: @headers

      expect(body["outcome"]).to eq("skipped")
    end

    it "blames google rather than itself when places will not answer" do
      stub_request(:post, Lml::GooglePlacesApiClient::FIND_URL).to_return(status: 403, body: "api not enabled")

      post "/v1/admin/venues/#{@tote.id}/place_lookup", headers: @headers

      expect(response).to have_http_status(:bad_gateway)
      expect(body["error"]).to include("Places API")
    end

    it "needs an admin token like everything else here" do
      post "/v1/admin/venues/#{@tote.id}/place_lookup"

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
