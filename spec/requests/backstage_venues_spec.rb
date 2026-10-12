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
  end

  it "tells a user with no venues that they have none" do
    sign_in create(:lml_user)

    get "/backstage/venues"

    expect(response.body).to include("You haven't been allocated any venues yet.")
  end
end
