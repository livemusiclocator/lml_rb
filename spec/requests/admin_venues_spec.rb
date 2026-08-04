# frozen_string_literal: true

require "rails_helper"

describe "admin venues" do
  before do
    host! "api.lml.live"

    @admin_user = Lml::AdminUser.create!(
      email: "admin_venues_spec@example.com",
      username: "researcher",
      password: "supersecret123",
      password_confirmation: "supersecret123",
      time_zone: "Australia/Melbourne",
    )
    sign_in @admin_user, scope: :admin_user

    @components = {
      "name" => "Hotel Esplanade",
      "street_number" => "11",
      "route" => "The Esplanade",
      "locality" => "St Kilda",
      "administrative_area_level_1" => "VIC",
      "administrative_area_level_1_long" => "Victoria",
      "postal_code" => "3182",
      "country" => "AU",
      "latitude" => -37.8676,
    }
  end

  describe "the show page" do
    before do
      @venue = create(
        :lml_venue,
        name: "The Espy",
        address_components: @components,
        google_place_id: "place-espy",
      )
    end

    it "shows the resolved places data" do
      get "/admin/venues/#{@venue.id}"

      expect(response.body).to include("Google Places")
      expect(response.body).to include("place-espy")
      expect(response.body).to include("Hotel Esplanade")
    end

    it "formats the components as indented json" do
      get "/admin/venues/#{@venue.id}"

      expect(response.body).to include("&quot;route&quot;: &quot;The Esplanade&quot;")
    end

    it "shows only the identity keys under what matching is done on" do
      get "/admin/venues/#{@venue.id}"

      # Active Admin titleizes the row label, so this is "Matched On" in the markup.
      matched_on = response.body[%r{Matched On.*?</pre>}m]

      expect(matched_on).to include("street_number")
      # latitude drifts and the _long forms restate a matched key, so neither is matched on.
      expect(matched_on).not_to include("latitude")
      expect(matched_on).not_to include("administrative_area_level_1_long")
    end

    it "says so for a venue that has never been resolved" do
      venue = create(:lml_venue, name: "Hand Entered")

      get "/admin/venues/#{venue.id}"

      expect(response.body).to include("Not resolved through the Places API")
    end
  end

  describe "the form" do
    before do
      @venue = create(
        :lml_venue,
        name: "The Espy",
        address_components: @components,
        google_place_id: "place-espy",
      )
    end

    it "does not offer the places data for editing" do
      get "/admin/venues/#{@venue.id}/edit"

      expect(response.body).not_to include("venue_address_components")
      expect(response.body).not_to include("venue_google_place_id")
    end

    # Derived data has one writer - the importer. Anything that reached it through the form would be
    # silently undone by the next run, so permit_params has to keep refusing it.
    it "ignores places data submitted anyway" do
      patch "/admin/venues/#{@venue.id}", params: {
        lml_venue: {
          name: "The Espy",
          time_zone: "Australia/Melbourne",
          address_components: { "route" => "Somewhere Else" }.to_json,
          google_place_id: "tampered",
        },
      }

      expect(@venue.reload.address_components).to eq(@components)
      expect(@venue.google_place_id).to eq("place-espy")
    end
  end
end
