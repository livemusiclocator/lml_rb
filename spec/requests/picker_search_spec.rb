# frozen_string_literal: true

require "rails_helper"

describe "picker search" do
  before do
    host! "api.lml.live"

    @admin_user = Lml::AdminUser.create!(
      email: "picker_search_spec@example.com",
      username: "picker",
      password: "supersecret123",
      password_confirmation: "supersecret123",
      time_zone: "Australia/Melbourne",
    )

    @tote = create(:lml_venue, name: "The Tote", location: "melbourne")
    @act = create(:lml_act, name: "Amyl and the Sniffers", country: "Australia")
    @gig = create(:lml_gig, name: "Sniffers Live", venue: @tote, date: "2026-09-01")
    @hidden = create(:lml_gig, name: "Sniffers Secret", venue: @tote, date: "2026-09-02", hidden: true)
  end

  describe "without an admin session" do
    %w[/acts/search /venues/search /gigs/search].each do |path|
      it "refuses #{path}" do
        get path, params: { q: "sniffers" }, headers: { "Accept" => "application/json" }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "with an admin session" do
    before { sign_in @admin_user, scope: :admin_user }

    # Acts carry two extras for the gig form's set list picker: the act as a set
    # line names it - which is not the label, see Lml::Act#set_list_name - and
    # the genres that picker copies onto the gig.
    it "returns id and label pairs for acts, with the set list extras" do
      @act.update!(location: "melbourne", genres: ["punk", "garage rock"])

      get "/acts/search", params: { q: "amyl" }

      expect(JSON.parse(response.body)).to eq(
        [{
          "id" => @act.id,
          "label" => "Amyl and the Sniffers (Australia)",
          "set_list_name" => "Amyl and the Sniffers (melbourne/Australia)",
          "genres" => ["punk", "garage rock"],
        }],
      )
    end

    it "sends an empty genre list for an act with no genres" do
      get "/acts/search", params: { q: "amyl" }

      expect(JSON.parse(response.body).first).to include(
        "set_list_name" => "Amyl and the Sniffers",
        "genres" => [],
      )
    end

    it "returns id and label pairs for venues" do
      get "/venues/search", params: { q: "tote" }

      expect(JSON.parse(response.body)).to eq(
        [{ "id" => @tote.id, "label" => "The Tote (melbourne)" }],
      )
    end

    it "returns id and label pairs for gigs" do
      get "/gigs/search", params: { q: "sniffers" }

      expect(JSON.parse(response.body)).to eq(
        [{ "id" => @gig.id, "label" => "Sniffers Live - The Tote (melbourne) - Tue, 01 Sep 2026" }],
      )
    end

    it "never offers a hidden gig to pick" do
      get "/gigs/search", params: { q: "sniffers" }

      expect(JSON.parse(response.body).map { |result| result["id"] }).not_to include(@hidden.id)
    end

    it "caps results so a blank query cannot dump the table" do
      create_list(:lml_act, 12)

      get "/acts/search", params: { q: "" }

      expect(JSON.parse(response.body).size).to eq(PickerResults::RESULT_LIMIT)
    end
  end

  # The gigs one never worked in the first place - the_api's ":id" always
  # claimed it - so it 404s via gigs#show rather than via an unknown route.
  # /venues/autocomplete is back, token gated - see venue_autocomplete_spec.
  describe "the withdrawn autocomplete endpoints" do
    %w[/acts/autocomplete /gigs/autocomplete].each do |path|
      it "does not serve #{path}" do
        get path

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
