# frozen_string_literal: true

require "rails_helper"

describe "admin api gigs" do
  before do
    host! "api.lml.live"

    @admin = create(:lml_user, :admin)
    @headers = { "Authorization" => "Bearer #{Lml::ApiToken.issue!(user: @admin, name: "Research").plaintext}" }

    @vine = create(:lml_venue, name: "Golden Vine Hotel", location: "bendigo")
    @tote = create(:lml_venue, name: "The Tote", location: "melbourne")

    @swift = create(:lml_gig, name: "Andrew Swift", date: Date.current + 25, venue: @vine)
    @swift.update!(start_time: "20:00", finish_time: "23:30")
    Lml::Set.create_for_gig_from_line!(@swift, "Andrew Swift | 20:30")
    Lml::Price.create_for_gig_from_line!(@swift, "30.00 | presale")

    @open_mic = create(:lml_gig, name: "Open Mic night", date: Date.current + 3, venue: @vine)
    @last_week = create(:lml_gig, name: "Smashed Pie", date: Date.current - 7, venue: @vine)
    @elsewhere = create(:lml_gig, name: "Sniffers Live", date: Date.current + 4, venue: @tote)
  end

  def body
    JSON.parse(response.body)
  end

  describe "listing" do
    it "returns upcoming gigs in date order with pagination metadata" do
      get "/v1/admin/gigs", headers: @headers

      expect(body["gigs"].map { |g| g["name"] }).to eq(["Open Mic night", "Sniffers Live", "Andrew Swift"])
      expect(body["meta"]).to eq({ "page" => 1, "per_page" => 50, "total" => 3 })
    end

    it "leaves the past out unless it is asked for" do
      get "/v1/admin/gigs", headers: @headers

      expect(body["gigs"].map { |g| g["name"] }).not_to include("Smashed Pie")
    end

    it "reaches back when given an explicit date_from" do
      get "/v1/admin/gigs", params: { date_from: (Date.current - 30).iso8601 }, headers: @headers

      expect(body["gigs"].map { |g| g["name"] }).to include("Smashed Pie")
    end

    it "filters to one venue" do
      get "/v1/admin/gigs", params: { venue_id: @vine.id }, headers: @headers

      expect(body["gigs"].map { |g| g["name"] }).to eq(["Open Mic night", "Andrew Swift"])
    end

    it "filters to a date range" do
      get "/v1/admin/gigs",
          params: { venue_id: @vine.id, date_from: Date.current.iso8601, date_to: (Date.current + 7).iso8601 },
          headers: @headers

      expect(body["gigs"].map { |g| g["name"] }).to eq(["Open Mic night"])
    end

    it "pages through the collection" do
      get "/v1/admin/gigs", params: { venue_id: @vine.id, per_page: 1, page: 2 }, headers: @headers

      expect(body["gigs"].map { |g| g["name"] }).to eq(["Andrew Swift"])
    end

    it "refuses to dump more than a hundred at a time however much is asked for" do
      get "/v1/admin/gigs", params: { per_page: 5000 }, headers: @headers

      expect(body["meta"]["per_page"]).to eq(100)
    end

    it "says which date it could not read rather than blowing up" do
      get "/v1/admin/gigs", params: { date_from: "next tuesdayish" }, headers: @headers

      expect(response).to have_http_status(:bad_request)
      expect(body["error"]).to include("date_from")
    end

    # The public API and the pickers both hide these. This endpoint exists so a
    # caller can tell that a show is already here, and a draft still counts.
    it "includes drafts and hidden gigs, which the public api would not" do
      create(:lml_gig, name: "Unannounced", date: Date.current + 5, venue: @vine, status: "draft")
      create(:lml_gig, name: "Pulled", date: Date.current + 6, venue: @vine, hidden: true)

      get "/v1/admin/gigs", params: { venue_id: @vine.id }, headers: @headers

      expect(body["gigs"].map { |g| g["name"] }).to include("Unannounced", "Pulled")
    end

    it "carries the detail a caller needs to recognise a gig it already has" do
      get "/v1/admin/gigs", params: { venue_id: @vine.id }, headers: @headers

      swift = body["gigs"].find { |g| g["name"] == "Andrew Swift" }
      expect(swift).to include(
        "id" => @swift.id,
        "date" => (Date.current + 25).iso8601,
        "start_time" => "20:00",
        "finish_time" => "23:30",
        "status" => "confirmed",
      )
      expect(swift["venue"]).to eq({ "id" => @vine.id, "name" => "Golden Vine Hotel" })
      expect(swift["acts"].map { |a| a["name"] }).to eq(["Andrew Swift"])
      expect(swift["prices"]).to eq([{ "amount" => "$30.00", "description" => "presale" }])
    end
  end

  describe "showing" do
    it "returns the gig" do
      get "/v1/admin/gigs/#{@swift.id}", headers: @headers

      expect(body["gig"]).to include("id" => @swift.id, "name" => "Andrew Swift")
    end

    it "returns a json 404 for a gig that does not exist" do
      get "/v1/admin/gigs/#{SecureRandom.uuid}", headers: @headers

      expect(response).to have_http_status(:not_found)
      expect(body["error"]).to be_present
    end
  end

  describe "clipper" do
    it "renders the venue's upcoming gigs as clipper text" do
      get "/v1/admin/gigs/clipper", params: { venue_id: @vine.id }, headers: @headers

      expect(response.body).to include("name: Andrew Swift")
      expect(response.body).to include("date: #{(Date.current + 25).iso8601}")
      expect(response.body).to include("start_time: 20:00")
      expect(response.body).not_to include("Sniffers Live")
    end

    # Half a clipper file is not a clipper file - it would upload as a partial
    # week and quietly leave the tail out.
    it "ignores pagination" do
      get "/v1/admin/gigs/clipper", params: { venue_id: @vine.id, per_page: 1 }, headers: @headers

      expect(response.body).to include("Open Mic night")
      expect(response.body).to include("Andrew Swift")
    end
  end

  describe "authentication" do
    it "refuses a request with no token" do
      get "/v1/admin/gigs"

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
