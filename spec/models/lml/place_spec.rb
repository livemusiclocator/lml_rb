# frozen_string_literal: true

require "rails_helper"

RSpec.describe Lml::Place do
  def component(type, short, long = nil)
    { "types" => [type], "shortText" => short, "longText" => long || short }
  end

  def payload(**overrides)
    {
      "id" => "place-espy",
      "displayName" => { "text" => "Hotel Esplanade" },
      "formattedAddress" => "11 The Esplanade, St Kilda VIC 3182",
      "businessStatus" => "OPERATIONAL",
      "googleMapsUri" => "https://maps.google.com/?cid=espy",
      "timeZone" => { "id" => "Australia/Melbourne" },
      "location" => { "latitude" => -37.8676, "longitude" => 144.9756 },
      "addressComponents" => [
        component("street_number", "11"),
        component("route", "The Esplanade"),
        component("administrative_area_level_1", "VIC", "Victoria"),
      ],
    }.merge(overrides)
  end

  describe "#components" do
    it "flattens the components into a hash keyed by type" do
      expect(Lml::Place.new(payload).components).to include(
        "street_number" => "11",
        "route" => "The Esplanade",
        "administrative_area_level_1" => "VIC",
      )
    end

    it "keeps the long form only where it differs from the short one" do
      components = Lml::Place.new(payload).components

      expect(components["administrative_area_level_1_long"]).to eq("Victoria")
      expect(components).not_to have_key("route_long")
    end

    it "carries the coordinates and the resolved name" do
      expect(Lml::Place.new(payload).components).to include(
        "latitude" => -37.8676,
        "longitude" => 144.9756,
        "name" => "Hotel Esplanade",
      )
    end

    it "buckets a component google gave no type for" do
      place = Lml::Place.new(payload("addressComponents" => [component_without_types]))

      expect(place.components["unknown"]).to eq("Something")
    end

    def component_without_types
      { "types" => [], "shortText" => "Something", "longText" => "Something" }
    end

    it "copes with a place carrying no components or location at all" do
      place = Lml::Place.new({ "id" => "bare" })

      expect(place.components).to eq({})
      expect(place.identity).to eq({})
    end
  end

  describe "#identity" do
    it "keeps only the keys that decide whether two venues share an address" do
      expect(Lml::Place.new(payload).identity).to eq(
        "street_number" => "11",
        "route" => "The Esplanade",
        "administrative_area_level_1" => "VIC",
      )
    end

    it "excludes the coordinates, which drift, and the long forms, which restate a key" do
      identity = Lml::Place.new(payload).identity

      expect(identity).not_to have_key("latitude")
      expect(identity).not_to have_key("administrative_area_level_1_long")
      expect(identity).not_to have_key("name")
    end
  end

  describe "#time_zone" do
    it "takes a zone we recognise" do
      expect(Lml::Place.new(payload).time_zone).to eq("Australia/Melbourne")
    end

    it "maps a deprecated iana name onto the name we use" do
      place = Lml::Place.new(payload("timeZone" => { "id" => "Australia/Victoria" }))

      expect(place.time_zone).to eq("Australia/Melbourne")
    end

    # A venue whose time_zone is outside CANONICAL_TIMEZONES cannot be saved, so no answer is
    # better than one that breaks the record.
    it "refuses a zone that would not validate" do
      place = Lml::Place.new(payload("timeZone" => { "id" => "Europe/London" }))

      expect(place.time_zone).to be_nil
    end

    it "copes with a place google gave no zone for" do
      expect(Lml::Place.new(payload("timeZone" => nil)).time_zone).to be_nil
    end
  end

  describe "#attributes_for" do
    it "gives everything for a venue that has nothing" do
      attributes = Lml::Place.new(payload).attributes_for(Lml::Venue.new)

      expect(attributes).to include(
        google_place_id: "place-espy",
        google_business_status: "OPERATIONAL",
        time_zone: "Australia/Melbourne",
        address: "11 The Esplanade, St Kilda VIC 3182",
        latitude: -37.8676,
      )
    end

    it "fills the map link from the place's own listing, without the api's tracking parameter" do
      place = Lml::Place.new(payload("googleMapsUri" => "https://maps.google.com/?cid=3264005606005329900&g_mp=Cidnb29n"))

      attributes = place.attributes_for(Lml::Venue.new)

      expect(attributes[:location_url]).to eq("https://maps.google.com/?cid=3264005606005329900")
    end

    it "leaves a map link somebody chose" do
      venue = Lml::Venue.new(location_url: "https://maps.example/espy")

      expect(Lml::Place.new(payload).attributes_for(venue)).not_to have_key(:location_url)
    end

    it "leaves out anything the venue already has a value for" do
      venue = Lml::Venue.new(time_zone: "Australia/Sydney", address: "somewhere else")

      attributes = Lml::Place.new(payload).attributes_for(venue)

      expect(attributes).not_to have_key(:time_zone)
      expect(attributes).not_to have_key(:address)
    end

    # Re-resolving could point a venue at a different place entirely, which is worse than holding a
    # slightly stale address.
    it "does not re-point a venue that is already resolved" do
      venue = Lml::Venue.new(address_components: { "route" => "somewhere else" }, google_place_id: "other")

      attributes = Lml::Place.new(payload).attributes_for(venue)

      expect(attributes).not_to have_key(:address_components)
      expect(attributes).not_to have_key(:google_place_id)
    end

    # Whether a venue is still trading is the one thing here that really changes.
    it "always refreshes the business status" do
      venue = Lml::Venue.new(
        address_components: { "route" => "somewhere else" },
        google_business_status: "OPERATIONAL",
      )
      place = Lml::Place.new(payload("businessStatus" => "CLOSED_PERMANENTLY"))

      expect(place.attributes_for(venue)).to include(google_business_status: "CLOSED_PERMANENTLY")
    end

    # Identity is one fact, so a venue holding components but no place id keeps both as they are
    # rather than being told its address came from this place.
    it "treats identity as all or nothing" do
      venue = Lml::Venue.new(address_components: { "route" => "somewhere else" }, google_place_id: nil)

      attributes = Lml::Place.new(payload).attributes_for(venue)

      expect(attributes).not_to have_key(:address_components)
      expect(attributes).not_to have_key(:google_place_id)
    end

    # Nothing Google says is thrown away - but only onto the venue it is about.
    describe "the whole payload" do
      it "goes onto a venue being resolved to this place" do
        expect(Lml::Place.new(payload).attributes_for(Lml::Venue.new)).to include(google_place: payload)
      end

      it "replaces the last answer for a venue already resolved to this place" do
        venue = Lml::Venue.new(
          address_components: { "route" => "The Esplanade" },
          google_place_id: "place-espy",
          google_place: { "id" => "place-espy", "displayName" => { "text" => "Old name" } },
        )

        expect(Lml::Place.new(payload).attributes_for(venue)).to include(google_place: payload)
      end

      it "stays off a venue resolved to some other place" do
        venue = Lml::Venue.new(address_components: { "route" => "somewhere else" }, google_place_id: "other")

        expect(Lml::Place.new(payload).attributes_for(venue)).not_to have_key(:google_place)
      end
    end
  end

  describe "#closed_permanently?" do
    it "is true only for a permanently closed place" do
      expect(Lml::Place.new(payload("businessStatus" => "CLOSED_PERMANENTLY"))).to be_closed_permanently
      expect(Lml::Place.new(payload)).not_to be_closed_permanently
      expect(Lml::Place.new(payload("businessStatus" => "CLOSED_TEMPORARILY"))).not_to be_closed_permanently
    end
  end

  describe "#settled_for" do
    it "records when the answer it keeps was fetched" do
      freeze_time do
        settled = Lml::Place.new(payload).settled_for(Lml::Venue.new)

        expect(settled).to include(google_place: payload, google_place_fetched_at: Time.current)
      end
    end
  end

  describe "#address" do
    it "is the short form, without the state, postcode and country" do
      place = Lml::Place.new(payload("shortFormattedAddress" => "11 The Esplanade, St Kilda"))

      expect(place.address).to eq("11 The Esplanade, St Kilda")
      expect(place.attributes_for(Lml::Venue.new)[:address]).to eq("11 The Esplanade, St Kilda")
      expect(place.form_attributes[:address]).to eq("11 The Esplanade, St Kilda")
    end

    it "falls back to the full address where Google gives no short one" do
      expect(Lml::Place.new(payload).address).to eq("11 The Esplanade, St Kilda VIC 3182")
    end
  end

  describe "#form_attributes" do
    it "starts a new venue from everything the place says about it" do
      place = Lml::Place.new(
        payload(
          "websiteUri" => "https://espy.com.au",
          "nationalPhoneNumber" => "(03) 9534 0211",
          "addressComponents" => [
            component("postal_code", "3182"),
            component("administrative_area_level_2", "Port Phillip", "City of Port Phillip"),
          ],
        ),
      )

      expect(place.form_attributes).to eq(
        name: "Hotel Esplanade",
        address: "11 The Esplanade, St Kilda VIC 3182",
        postcode: "3182",
        lga: "City of Port Phillip",
        lat_lng: "-37.8676, 144.9756",
        time_zone: "Australia/Melbourne",
        website: "https://espy.com.au",
        phone: "(03) 9534 0211",
        location_url: "https://maps.google.com/?cid=espy",
      )
    end

    it "leaves out what the place does not say" do
      place = Lml::Place.new(payload("location" => nil, "addressComponents" => [], "googleMapsUri" => nil))

      expect(place.form_attributes.keys).to contain_exactly(:name, :address, :time_zone)
    end
  end
end
