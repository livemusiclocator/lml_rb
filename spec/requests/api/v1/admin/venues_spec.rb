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
end
