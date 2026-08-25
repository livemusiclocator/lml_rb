# frozen_string_literal: true

require "rails_helper"

describe "acts" do
  before do
    host! "api.lml.live"

    @venue = Lml::Venue.create!(
      name: "The Tote",
      address: "67-71 Johnston St, Collingwood VIC 3066",
      postcode: 3066,
      location: "melbourne",
      time_zone: "Australia/Melbourne",
    )
    @act = Lml::Act.create!(
      name: "Amyl and the Sniffers",
      country: "Australia",
      location: "melbourne",
      genres: ["punk", "garage rock"],
      website: "https://amyl.example",
      instagram: "amylandthesniffers",
      email: "amyl@example.com",
    )
  end

  def create_gig(name, date, attributes = {})
    gig = Lml::Gig.create!({ name: name, venue: @venue, date: date, status: :confirmed }.merge(attributes))
    Lml::Set.create!(gig: gig, act: @act, start_offset: 1200)
    gig
  end

  describe "show" do
    it "returns the act" do
      get "/acts/#{@act.id}"

      expect(JSON.parse(response.body)).to include(
        "id" => @act.id,
        "name" => "Amyl and the Sniffers",
        "country" => "Australia",
        "location" => "melbourne",
        "genres" => ["punk", "garage rock"],
        "website" => "https://amyl.example",
        "instagram_url" => "https://www.instagram.com/amylandthesniffers",
      )
    end

    # The picker is admin only, but an act page is for everyone.
    it "does not need an admin session" do
      get "/acts/#{@act.id}"

      expect(response).to have_http_status(:ok)
    end

    it "does not publish the act's email address" do
      get "/acts/#{@act.id}"

      expect(JSON.parse(response.body)).not_to have_key("email")
    end

    it "renders the act the same way a gig does" do
      gig = create_gig("Sniffers Live", Date.current + 3)

      get "/acts/#{@act.id}"
      from_act = JSON.parse(response.body).except("upcoming_gigs")
      get "/gigs/#{gig.id}"
      from_gig = JSON.parse(response.body)["sets"].first["act"]

      expect(from_act).to eq(from_gig)
    end

    it "404s for an unknown act" do
      get "/acts/#{SecureRandom.uuid}"

      expect(response).to have_http_status(:not_found)
    end

    it "leaves the picker route alone" do
      get "/acts/search", params: { q: "amyl" }

      expect(response).to have_http_status(:unauthorized)
    end

    describe "upcoming gigs" do
      it "lists them with their venue, soonest first" do
        create_gig("Later", Date.current + 10)
        create_gig("Sooner", Date.current + 2)

        get "/acts/#{@act.id}"
        gigs = JSON.parse(response.body)["upcoming_gigs"]

        expect(gigs.map { |gig| gig["name"] }).to eq(["Sooner", "Later"])
        expect(gigs.first["venue"]).to include("id" => @venue.id, "name" => "The Tote")
      end

      it "includes a gig on today" do
        create_gig("Tonight", Date.current)

        get "/acts/#{@act.id}"

        expect(upcoming_names).to eq(["Tonight"])
      end

      it "leaves out gigs that have been and gone" do
        create_gig("Last Week", Date.current - 7)

        get "/acts/#{@act.id}"

        expect(upcoming_names).to be_empty
      end

      # An act page is public, so it gets the same visible scope as every other
      # public gig path. A hidden gig is one nobody has announced yet.
      it "leaves out hidden gigs" do
        create_gig("Hush Hush", Date.current + 3, hidden: true)

        get "/acts/#{@act.id}"

        expect(upcoming_names).to be_empty
      end

      it "leaves out draft gigs" do
        create_gig("Still Cooking", Date.current + 3, status: :draft)

        get "/acts/#{@act.id}"

        expect(upcoming_names).to be_empty
      end

      it "lists a gig once even when the act plays two sets at it" do
        gig = create_gig("Twice Over", Date.current + 5)
        Lml::Set.create!(gig: gig, act: @act, start_offset: 1380)

        get "/acts/#{@act.id}"

        expect(upcoming_names).to eq(["Twice Over"])
      end

      it "leaves out another act's gigs" do
        other = Lml::Act.create!(name: "Someone Else")
        theirs = Lml::Gig.create!(name: "Not Ours", venue: @venue, date: Date.current + 3, status: :confirmed)
        Lml::Set.create!(gig: theirs, act: other, start_offset: 1200)

        get "/acts/#{@act.id}"

        expect(upcoming_names).to be_empty
      end
    end
  end

  # ":id" without a constraint spent years swallowing /gigs/autocomplete, so this
  # one matches a uuid and nothing else - which has to be asserted on the route
  # rather than the response, since an unknown act 404s either way.
  describe "the show route", type: :routing do
    it "routes a uuid to the namespaced api controller" do
      id = SecureRandom.uuid

      expect(get: "http://api.lml.live/acts/#{id}")
        .to route_to(controller: "api/acts", action: "show", id: id, format: "json")
    end

    it "does not route anything that is not a uuid" do
      expect(get: "http://api.lml.live/acts/something-we-might-add-later").not_to be_routable
    end
  end

  def upcoming_names
    JSON.parse(response.body)["upcoming_gigs"].map { |gig| gig["name"] }
  end
end
