# frozen_string_literal: true

require "rails_helper"

describe "venues" do
  before do
    host! "api.lml.live"

    @venue = Lml::Venue.create!(
      name: "The Tote",
      address: "67-71 Johnston St, Collingwood VIC 3066",
      postcode: 3066,
      location: "melbourne",
      time_zone: "Australia/Melbourne",
      capacity: 500,
      website: "https://thetotehotel.com",
    )
    @act = Lml::Act.create!(name: "Amyl and the Sniffers", country: "Australia")
  end

  def create_gig(name, date, attributes = {})
    gig = Lml::Gig.create!({ name: name, venue: @venue, date: date, status: :confirmed }.merge(attributes))
    Lml::Set.create!(gig: gig, act: @act, start_offset: 1200)
    gig
  end

  describe "show" do
    it "returns the venue" do
      get "/venues/#{@venue.id}"

      expect(JSON.parse(response.body)).to include(
        "id" => @venue.id,
        "name" => "The Tote",
        "address" => "67-71 Johnston St, Collingwood VIC 3066",
        "postcode" => "3066",
        "capacity" => 500,
        "website" => "https://thetotehotel.com",
      )
    end

    # The picker and the autocomplete are gated; a venue page is for everyone.
    it "does not need an admin session or a token" do
      get "/venues/#{@venue.id}"

      expect(response).to have_http_status(:ok)
    end

    it "renders the venue the same way a gig does" do
      gig = create_gig("Sniffers Live", Date.current + 3)

      get "/venues/#{@venue.id}"
      from_venue = JSON.parse(response.body).except("upcoming_gigs")
      get "/gigs/#{gig.id}"
      from_gig = JSON.parse(response.body)["venue"]

      expect(from_venue).to eq(from_gig)
    end

    it "404s for an unknown venue" do
      get "/venues/#{SecureRandom.uuid}"

      expect(response).to have_http_status(:not_found)
    end

    describe "upcoming gigs" do
      it "lists them soonest first, with who is playing" do
        create_gig("Later", Date.current + 10)
        create_gig("Sooner", Date.current + 2)

        get "/venues/#{@venue.id}"
        gigs = JSON.parse(response.body)["upcoming_gigs"]

        expect(gigs.map { |gig| gig["name"] }).to eq(%w[Sooner Later])
        expect(gigs.first["sets"].map { |set| set["act"]["name"] }).to eq(["Amyl and the Sniffers"])
      end

      it "includes a gig on today" do
        create_gig("Tonight", Date.current)

        get "/venues/#{@venue.id}"

        expect(upcoming_names).to eq(["Tonight"])
      end

      it "leaves out gigs that have been and gone" do
        create_gig("Last Week", Date.current - 7)

        get "/venues/#{@venue.id}"

        expect(upcoming_names).to be_empty
      end

      # Same visible scope as every other public gig path.
      it "leaves out hidden gigs" do
        create_gig("Hush Hush", Date.current + 3, hidden: true)

        get "/venues/#{@venue.id}"

        expect(upcoming_names).to be_empty
      end

      it "leaves out draft gigs" do
        create_gig("Still Cooking", Date.current + 3, status: :draft)

        get "/venues/#{@venue.id}"

        expect(upcoming_names).to be_empty
      end

      it "leaves out another venue's gigs" do
        elsewhere = Lml::Venue.create!(name: "The Night Cat", location: "melbourne",
                                       time_zone: "Australia/Melbourne",)
        theirs = Lml::Gig.create!(name: "Not Ours", venue: elsewhere, date: Date.current + 3, status: :confirmed)
        Lml::Set.create!(gig: theirs, act: @act, start_offset: 1200)

        get "/venues/#{@venue.id}"

        expect(upcoming_names).to be_empty
      end

      it "renders a gig's sets the same way the gig endpoint does" do
        gig = create_gig("Sniffers Live", Date.current + 3)

        get "/venues/#{@venue.id}"
        from_venue = JSON.parse(response.body)["upcoming_gigs"].first["sets"]
        get "/gigs/#{gig.id}"
        from_gig = JSON.parse(response.body)["sets"]

        expect(from_venue).to eq(from_gig)
      end
    end
  end

  describe "the show route", type: :routing do
    it "routes a uuid to the namespaced api controller" do
      id = SecureRandom.uuid

      expect(get: "http://api.lml.live/venues/#{id}")
        .to route_to(controller: "api/venues", action: "show", id: id, format: "json")
    end

    it "does not route anything that is not a uuid" do
      expect(get: "http://api.lml.live/venues/something-we-might-add-later").not_to be_routable
    end

    # The pickers were there first and must keep their paths.
    it "leaves the picker routes alone" do
      expect(get: "http://api.lml.live/venues/search").to route_to(controller: "venues", action: "search",
                                                                   format: "json",)
      expect(get: "http://api.lml.live/venues/autocomplete").to route_to(controller: "venues", action: "autocomplete",
                                                                         format: "json",)
    end
  end

  def upcoming_names
    JSON.parse(response.body)["upcoming_gigs"].map { |gig| gig["name"] }
  end
end
