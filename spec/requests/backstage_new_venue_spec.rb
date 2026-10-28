# frozen_string_literal: true

require "rails_helper"

describe "adding a venue from backstage" do
  before do
    host! "www.livemusiclocator.com.au"

    @place = {
      "id" => "place-tote",
      "displayName" => { "text" => "The Tote Hotel" },
      "formattedAddress" => "71 Johnston St, Collingwood VIC 3066",
      "businessStatus" => "OPERATIONAL",
      "timeZone" => { "id" => "Australia/Melbourne" },
      "location" => { "latitude" => -37.7986, "longitude" => 144.9876 },
      "websiteUri" => "https://thetotehotel.com",
      "rating" => 4.5,
      "addressComponents" => [
        { "types" => ["postal_code"], "shortText" => "3066", "longText" => "3066" },
        { "types" => ["route"], "shortText" => "Johnston St", "longText" => "Johnston Street" },
      ],
    }
  end

  it "keeps somebody who is not an admin out" do
    sign_in create(:lml_user)

    get "/backstage/venues/new"
    expect(response).to redirect_to("/backstage")

    expect { post "/backstage/venues", params: { venue: { name: "The Tote" } } }.not_to change(Lml::Venue, :count)
    get "/backstage/search/places", params: { q: "tote" }
    expect(response).to redirect_to("/backstage")
  end

  describe "as an admin" do
    before { sign_in create(:lml_user, :admin) }

    it "suggests places, leaving out searches that are not places" do
      stub_request(:post, Lml::GooglePlacesApiClient::AUTOCOMPLETE_URL)
        .with(body: hash_including("input" => "tote", "sessionToken" => "session-1", "includedRegionCodes" => ["AU"]))
        .to_return(status: 200,
          body: {
            suggestions: [
              {
                placePrediction: {
                  placeId: "place-tote",
                  text: { text: "The Tote Hotel, Johnston St, Collingwood" },
                },
              },
              { queryPrediction: { text: { text: "tote bags" } } },
            ],
          }.to_json,)

      get "/backstage/search/places", params: { q: "tote", session_token: "session-1" }

      expect(response.parsed_body).to eq(
        [
          {
            "id" => "place-tote",
            "label" => "The Tote Hotel, Johnston St, Collingwood",
          },
        ],
      )
    end

    it "answers a place with the fields to fill in and the whole response" do
      stub_request(:get, %r{places/place-tote}).to_return(status: 200, body: @place.to_json)

      get "/backstage/places/place-tote", params: { session_token: "session-1" }

      expect(response.parsed_body["attributes"]).to include("name" => "The Tote Hotel", "postcode" => "3066")
      expect(response.parsed_body["place"]).to eq(@place)
      expect(response.parsed_body["existing"]).to be_nil
    end

    it "says when the place is already a venue" do
      venue = create(:lml_venue, name: "The Tote", google_place_id: "place-tote")
      stub_request(:get, %r{places/place-tote}).to_return(status: 200, body: @place.to_json)

      get "/backstage/places/place-tote"

      expect(response.parsed_body["existing"]).to eq("name" => "The Tote", "url" => "/backstage/venues/#{venue.id}")
    end

    it "reports google failing rather than erroring" do
      stub_request(:get, %r{places/place-tote}).to_return(status: 403, body: "denied")

      get "/backstage/places/place-tote"

      expect(response).to have_http_status(:bad_gateway)
      expect(response.parsed_body["error"]).to include("Google Places did not answer")
    end

    it "adds the venue, keeping everything google said about it" do
      post "/backstage/venues",
        params: {
          venue: {
            name: "The Tote",
            location: "melbourne",
            time_zone: "Australia/Melbourne",
            google_place: @place.to_json,
          },
        }

      venue = Lml::Venue.sole
      expect(response).to redirect_to("/backstage/venues/#{venue.id}")
      expect(venue.name).to eq("The Tote")
      expect(venue.google_place).to eq(@place)
      expect(venue.google_place_id).to eq("place-tote")
      expect(venue.google_business_status).to eq("OPERATIONAL")
      expect(venue.address_components).to include("route" => "Johnston St", "postal_code" => "3066")
      expect(venue.address).to eq("71 Johnston St, Collingwood VIC 3066")
    end

    it "adds a venue by hand, without google" do
      post "/backstage/venues", params: { venue: { name: "Somebody's Shed", time_zone: "Australia/Hobart" } }

      venue = Lml::Venue.sole
      expect(venue.name).to eq("Somebody's Shed")
      expect(venue.google_place).to be_nil
    end

    it "refuses a second venue for the same place" do
      create(:lml_venue, name: "The Tote", google_place_id: "place-tote")

      expect do
        post "/backstage/venues",
          params: { venue: { name: "Tote again", time_zone: "Australia/Melbourne", google_place: @place.to_json } }
      end.not_to change(Lml::Venue, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("There is already a venue for that Google place")
    end

    it "refuses a venue without a name" do
      expect { post "/backstage/venues", params: { venue: { name: "", time_zone: "Australia/Melbourne" } } }
        .not_to change(Lml::Venue, :count)

      expect(response.body).to include("Name can&#39;t be blank")
    end
  end
end
