# frozen_string_literal: true

require "rails_helper"

describe "admin api acts" do
  before do
    host! "api.lml.live"

    @admin = create(:lml_user, :admin)
    @headers = { "Authorization" => "Bearer #{Lml::ApiToken.issue!(user: @admin, name: "Import").plaintext}" }

    @amyl = create(:lml_act, name: "Amyl and the Sniffers", country: "Australia")
    @cable = create(:lml_act, name: "Cable Ties", country: "Australia")
  end

  def body
    JSON.parse(response.body)
  end

  describe "listing" do
    it "returns acts in name order with pagination metadata" do
      get "/v1/admin/acts", headers: @headers

      expect(body["acts"].map { |a| a["name"] }).to eq(["Amyl and the Sniffers", "Cable Ties"])
      expect(body["meta"]).to eq({ "page" => 1, "per_page" => 50, "total" => 2 })
    end

    it "searches by name" do
      get "/v1/admin/acts", params: { q: "amyl" }, headers: @headers

      expect(body["acts"].map { |a| a["name"] }).to eq(["Amyl and the Sniffers"])
    end

    it "refuses to dump more than a hundred at a time however much is asked for" do
      get "/v1/admin/acts", params: { per_page: 5000 }, headers: @headers

      expect(body["meta"]["per_page"]).to eq(100)
    end
  end

  describe "showing" do
    before { @amyl.update!(genres: ["punk"], instagram: "https://www.instagram.com/amylsniffers") }

    it "returns the act with its genres and handles" do
      get "/v1/admin/acts/#{@amyl.id}", headers: @headers

      expect(body["act"]).to include("id" => @amyl.id, "name" => "Amyl and the Sniffers", "genres" => ["punk"])
      expect(body["act"]["handles"]).to include("instagram" => "amylsniffers")
    end

    it "returns a json 404 for an act that does not exist" do
      get "/v1/admin/acts/#{SecureRandom.uuid}", headers: @headers

      expect(response).to have_http_status(:not_found)
      expect(body["error"]).to be_present
    end
  end

  describe "creating" do
    it "creates an act" do
      post "/v1/admin/acts", headers: @headers, params: {
        act: { name: "Cash Savage", country: "Australia", genres: ["blues"] },
      }

      expect(response).to have_http_status(:created)
      expect(Lml::Act.find(body["act"]["id"]).genres).to eq(["blues"])
    end

    it "keeps the handle from a pasted social url" do
      post "/v1/admin/acts", headers: @headers, params: {
        act: { name: "Cash Savage", instagram: "https://www.instagram.com/cashsavage" },
      }

      expect(body["act"]["handles"]["instagram"]).to eq("cashsavage")
    end

    it "asks for the act key rather than guessing" do
      post "/v1/admin/acts", headers: @headers, params: { name: "Cash Savage" }

      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "updating" do
    it "updates the act" do
      patch "/v1/admin/acts/#{@amyl.id}", headers: @headers, params: { act: { country: "New Zealand" } }

      expect(@amyl.reload.country).to eq("New Zealand")
    end

    it "replaces the genre list wholesale rather than merging it" do
      @amyl.update!(genres: %w[punk garage])

      patch "/v1/admin/acts/#{@amyl.id}", headers: @headers, params: { act: { genres: ["pub rock"] } }

      expect(@amyl.reload.genres).to eq(["pub rock"])
    end

    it "clears a handle when given null" do
      @amyl.update!(instagram: "amylsniffers")

      patch "/v1/admin/acts/#{@amyl.id}", headers: @headers, params: { act: { instagram: nil } }

      expect(response).to have_http_status(:ok)
      expect(@amyl.reload.instagram).to be_nil
    end
  end
end
