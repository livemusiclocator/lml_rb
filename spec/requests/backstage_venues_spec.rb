# frozen_string_literal: true

require "rails_helper"

describe "backstage venues" do
  before do
    host! "www.livemusiclocator.com.au"

    @manager = create(:lml_user)
    @venue = create(:lml_venue, name: "The Tote")
    @other_venue = create(:lml_venue, name: "The Corner")
    Lml::VenueManager.create!(user: @manager, venue: @venue)
  end

  it "refuses a signed out visitor" do
    get "/backstage/venues"

    expect(response).to redirect_to("/backstage/login")
  end

  describe "as a venue manager" do
    before { sign_in @manager }

    it "lists only the venues they manage" do
      get "/backstage/venues"

      expect(response.body).to include("The Tote")
      expect(response.body).not_to include("The Corner")
    end

    it "does not find a venue somebody else manages" do
      get "/backstage/venues/#{@other_venue.id}"

      expect(response).to have_http_status(:not_found)
    end

    it "splits the venue's gigs into upcoming and recent" do
      create(:lml_gig, venue: @venue, name: "Next week's gig", date: Date.current + 7)
      create(:lml_gig, venue: @venue, name: "Last week's gig", date: Date.current - 7)
      create(:lml_gig, venue: @other_venue, name: "Somebody else's gig", date: Date.current + 7)

      get "/backstage/venues/#{@venue.id}"

      upcoming, recent = response.body.split("Recent gigs")
      expect(upcoming).to include("Next week&#39;s gig")
      expect(recent).to include("Last week&#39;s gig")
      expect(response.body).not_to include("Somebody else")
    end

    it "updates the details of a venue they manage" do
      patch "/backstage/venues/#{@venue.id}",
        params: {
          venue: { name: "The Tote Hotel", capacity: "250", tag_list: "pub, rock", lat_lng: "-37.80, 144.98" },
        }

      expect(response).to redirect_to("/backstage/venues/#{@venue.id}")
      @venue.reload
      expect(@venue.name).to eq("The Tote Hotel")
      expect(@venue.capacity).to eq(250)
      expect(@venue.tags).to eq(%w[pub rock])
      expect(@venue.latitude.to_f).to eq(-37.8)
    end

    it "shows what is wrong rather than saving a bad change" do
      patch "/backstage/venues/#{@venue.id}", params: { venue: { time_zone: "Mars/Olympus" } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("invalid time zone")
      expect(@venue.reload.time_zone).to eq("Australia/Melbourne")
    end

    it "does not update a venue somebody else manages" do
      patch "/backstage/venues/#{@other_venue.id}", params: { venue: { name: "Mine now" } }

      expect(response).to have_http_status(:not_found)
      expect(@other_venue.reload.name).to eq("The Corner")
    end
  end

  it "tells a user with no venues that they have none" do
    sign_in create(:lml_user)

    get "/backstage/venues"

    expect(response.body).to include("You haven't been allocated any venues yet.")
  end

  describe "as an admin" do
    before do
      @admin = create(:lml_user, :admin)
      Lml::VenueManager.create!(user: @admin, venue: @venue)
      sign_in @admin
    end

    it "lists their own venues and every other venue separately" do
      get "/backstage/venues"

      own, others = response.body.split("All other venues")
      expect(own).to include("The Tote")
      expect(others).to include("The Corner")
      expect(others).not_to include("The Tote")
    end

    it "searches the other venues" do
      create(:lml_venue, name: "The Gasometer")

      get "/backstage/venues", params: { q: "gaso" }

      others = response.body.split("All other venues").last
      expect(others).to include("The Gasometer")
      expect(others).not_to include("The Corner")
    end

    it "updates a venue they do not manage" do
      patch "/backstage/venues/#{@other_venue.id}", params: { venue: { name: "The Corner Hotel" } }

      expect(response).to redirect_to("/backstage/venues/#{@other_venue.id}")
      expect(@other_venue.reload.name).to eq("The Corner Hotel")
    end

    it "opens a venue they do not manage, and says so" do
      get "/backstage/venues/#{@other_venue.id}"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("because you're an admin")
    end
  end
end
