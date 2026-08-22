# frozen_string_literal: true

require "rails_helper"

# Two entries, one with sets and prices, so a single upload covers the shape a
# real one has.
CLIPPER = <<~CONTENT
  name: Sniffers Live
  date: 2026-09-01
  time: 20:00
  acts: Amyl and the Sniffers | Cable Ties
  price: 30.00 | presale
  ---
  name: Quiet Tuesday
  date: 2026-09-02
  time: 19:30
CONTENT

describe "admin api uploads" do
  before do
    host! "api.lml.live"

    @admin = create(:lml_user, :admin)
    @headers = {
      "Authorization" => "Bearer #{Lml::ApiToken.issue!(user: @admin, name: "Import").plaintext}",
    }

    @tote = create(:lml_venue, name: "The Tote", location: "melbourne", time_zone: "Australia/Melbourne")
  end

  def body
    JSON.parse(response.body)
  end

  describe "creating" do
    it "creates the gigs described by the content" do
      post "/v1/admin/uploads", headers: @headers, params: {
        upload: { content: CLIPPER, source: "cli", venue_id: @tote.id },
      }

      expect(response).to have_http_status(:created)
      expect(Lml::Gig.pluck(:name)).to contain_exactly("Sniffers Live", "Quiet Tuesday")
    end

    it "reports the gigs it touched, so a caller can see what landed" do
      post "/v1/admin/uploads", headers: @headers, params: {
        upload: { content: CLIPPER, source: "cli", venue_id: @tote.id },
      }

      expect(body["upload"]["gigs"].map { |gig| gig["name"] }).to eq(["Sniffers Live", "Quiet Tuesday"])
      expect(body["upload"]["gigs"].first["venue"]["name"]).to eq("The Tote")
    end

    it "records the upload as succeeded" do
      post "/v1/admin/uploads", headers: @headers, params: {
        upload: { content: CLIPPER, source: "cli", venue_id: @tote.id },
      }

      expect(body["upload"]).to include("status" => "Succeeded", "format" => "clipper", "source" => "cli")
    end

    it "builds the sets and prices from the entry" do
      post "/v1/admin/uploads", headers: @headers, params: {
        upload: { content: CLIPPER, source: "cli", venue_id: @tote.id },
      }

      gig = Lml::Gig.find_by(name: "Sniffers Live")
      expect(gig.sets.map { |set| set.act.name }).to eq(["Amyl and the Sniffers", "Cable Ties"])
      expect(gig.prices.count).to eq(1)
    end

    it "interprets the entry time in the venue's zone" do
      post "/v1/admin/uploads", headers: @headers, params: {
        upload: { content: CLIPPER, source: "cli", venue_id: @tote.id },
      }

      expect(Lml::Gig.find_by(name: "Sniffers Live").start_time).to eq("20:00")
    end

    it "leaves Time.zone alone, so the next request is not served in the venue's zone" do
      expect do
        post "/v1/admin/uploads", headers: @headers, params: {
          upload: { content: CLIPPER, source: "cli", venue_id: @tote.id },
        }
      end.not_to(change { Time.zone.name })
    end

    it "reports a rejected entry with the line it stopped on" do
      post "/v1/admin/uploads", headers: @headers, params: {
        upload: { content: "name: A gig\ndate: not a date\n", source: "cli", venue_id: @tote.id },
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(body["upload"]["error_description"]).to eq("1: 'not a date' is not a valid date")
      # Same `error` key every other failure uses, so one client rule covers all of them.
      expect(body["error"]).to eq("1: 'not a date' is not a valid date")
    end

    it "keeps a failed upload so its content can be fixed and resent" do
      post "/v1/admin/uploads", headers: @headers, params: {
        upload: { content: "name: A gig\ndate: not a date\n", source: "cli", venue_id: @tote.id },
      }

      expect(Lml::Upload.find(body["upload"]["id"]).status).to eq("Failed")
    end

    it "refuses an entry with no venue anywhere to hang it off" do
      post "/v1/admin/uploads", headers: @headers, params: {
        upload: { content: "name: A gig\ndate: 2026-09-01\n", source: "cli" },
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(body["upload"]["error_description"]).to eq("1: A venue is required")
    end

    it "lets an entry name its own venue, overriding the upload's" do
      other = create(:lml_venue, name: "Bridge Hotel", time_zone: "Australia/Melbourne")

      post "/v1/admin/uploads", headers: @headers, params: {
        upload: {
          content: "name: A gig\ndate: 2026-09-01\nvenue_id: #{other.id}\n",
          source: "cli", venue_id: @tote.id,
        },
      }

      expect(Lml::Gig.find_by(name: "A gig").venue).to eq(other)
    end

    it "asks for the upload key rather than guessing" do
      post "/v1/admin/uploads", headers: @headers, params: { content: CLIPPER }

      expect(response).to have_http_status(:bad_request)
    end

    it "refuses an upload too big to process inside the request" do
      entries = Array.new(101) { |n| "name: Gig #{n}\ndate: 2026-09-01\n" }.join("---\n")

      post "/v1/admin/uploads", headers: @headers, params: {
        upload: { content: entries, source: "cli", venue_id: @tote.id },
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(body["error"]).to include("the limit is 100")
    end

    it "creates nothing when it refuses an oversized upload" do
      entries = Array.new(101) { |n| "name: Gig #{n}\ndate: 2026-09-01\n" }.join("---\n")

      post "/v1/admin/uploads", headers: @headers, params: {
        upload: { content: entries, source: "cli", venue_id: @tote.id },
      }

      expect(Lml::Upload.count).to eq(0)
    end

    it "ignores a format the caller asks for - clipper is the only one there is" do
      post "/v1/admin/uploads", headers: @headers, params: {
        upload: { content: CLIPPER, source: "cli", venue_id: @tote.id, format: "csv" },
      }

      expect(Lml::Upload.last.format).to eq("clipper")
    end
  end

  describe "listing and showing" do
    before do
      @upload = Lml::Upload.create!(content: CLIPPER, source: "cli", venue: @tote, format: "clipper")
      @upload.process!
    end

    it "lists uploads newest first" do
      older = Lml::Upload.create!(content: "name: x\n", source: "older", venue: @tote, format: "clipper")
      older.update!(created_at: 2.days.ago)

      get "/v1/admin/uploads", headers: @headers

      expect(body["uploads"].map { |upload| upload["source"] }).to eq(%w[cli older])
    end

    it "filters by source" do
      Lml::Upload.create!(content: "name: x\n", source: "sheets", venue: @tote, format: "clipper")

      get "/v1/admin/uploads", params: { source: "cli" }, headers: @headers

      expect(body["uploads"].map { |upload| upload["source"] }).to eq(["cli"])
    end

    it "leaves the content out of a listing, which is bulky and rarely wanted" do
      get "/v1/admin/uploads", headers: @headers

      expect(body["uploads"].first).not_to have_key("content")
    end

    it "returns the content and the gigs when showing one" do
      get "/v1/admin/uploads/#{@upload.id}", headers: @headers

      expect(body["upload"]["content"]).to eq(CLIPPER)
      expect(body["upload"]["gigs"].length).to eq(2)
    end

    it "returns a json 404 for an upload that does not exist" do
      get "/v1/admin/uploads/#{SecureRandom.uuid}", headers: @headers

      expect(response).to have_http_status(:not_found)
    end
  end
end
