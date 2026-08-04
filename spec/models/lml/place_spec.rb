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
      expect(described_class.new(payload).components).to include(
        "street_number" => "11",
        "route" => "The Esplanade",
        "administrative_area_level_1" => "VIC",
      )
    end

    it "keeps the long form only where it differs from the short one" do
      components = described_class.new(payload).components

      expect(components["administrative_area_level_1_long"]).to eq("Victoria")
      expect(components).not_to have_key("route_long")
    end

    it "carries the coordinates and the resolved name" do
      expect(described_class.new(payload).components).to include(
        "latitude" => -37.8676,
        "longitude" => 144.9756,
        "name" => "Hotel Esplanade",
      )
    end

    it "buckets a component google gave no type for" do
      place = described_class.new(payload("addressComponents" => [component_without_types]))

      expect(place.components["unknown"]).to eq("Something")
    end

    def component_without_types
      { "types" => [], "shortText" => "Something", "longText" => "Something" }
    end

    it "copes with a place carrying no components or location at all" do
      place = described_class.new({ "id" => "bare" })

      expect(place.components).to eq({})
      expect(place.identity).to eq({})
    end
  end

  describe "#identity" do
    it "keeps only the keys that decide whether two venues share an address" do
      expect(described_class.new(payload).identity).to eq(
        "street_number" => "11",
        "route" => "The Esplanade",
        "administrative_area_level_1" => "VIC",
      )
    end

    it "excludes the coordinates, which drift, and the long forms, which restate a key" do
      identity = described_class.new(payload).identity

      expect(identity).not_to have_key("latitude")
      expect(identity).not_to have_key("administrative_area_level_1_long")
      expect(identity).not_to have_key("name")
    end
  end

  describe "#time_zone" do
    it "takes a zone we recognise" do
      expect(described_class.new(payload).time_zone).to eq("Australia/Melbourne")
    end

    it "maps a deprecated iana name onto the name we use" do
      place = described_class.new(payload("timeZone" => { "id" => "Australia/Victoria" }))

      expect(place.time_zone).to eq("Australia/Melbourne")
    end

    # A venue whose time_zone is outside CANONICAL_TIMEZONES cannot be saved, so no answer is
    # better than one that breaks the record.
    it "refuses a zone that would not validate" do
      place = described_class.new(payload("timeZone" => { "id" => "Europe/London" }))

      expect(place.time_zone).to be_nil
    end

    it "copes with a place google gave no zone for" do
      expect(described_class.new(payload("timeZone" => nil)).time_zone).to be_nil
    end
  end

  describe "#attributes_for" do
    it "gives everything for a venue that has nothing" do
      attributes = described_class.new(payload).attributes_for(Lml::Venue.new)

      expect(attributes).to include(
        google_place_id: "place-espy",
        google_business_status: "OPERATIONAL",
        time_zone: "Australia/Melbourne",
        location_url: "https://maps.google.com/?cid=espy",
        address: "11 The Esplanade, St Kilda VIC 3182",
        latitude: -37.8676,
      )
    end

    it "leaves out anything the venue already has a value for" do
      venue = Lml::Venue.new(time_zone: "Australia/Sydney", address: "somewhere else")

      attributes = described_class.new(payload).attributes_for(venue)

      expect(attributes).not_to have_key(:time_zone)
      expect(attributes).not_to have_key(:address)
    end

    # Re-resolving could point a venue at a different place entirely, which is worse than holding a
    # slightly stale address.
    it "does not re-point a venue that is already resolved" do
      venue = Lml::Venue.new(address_components: { "route" => "somewhere else" }, google_place_id: "other")

      attributes = described_class.new(payload).attributes_for(venue)

      expect(attributes).not_to have_key(:address_components)
      expect(attributes).not_to have_key(:google_place_id)
    end

    # Whether a venue is still trading is the one thing here that really changes.
    it "always refreshes the business status" do
      venue = Lml::Venue.new(
        address_components: { "route" => "somewhere else" },
        google_business_status: "OPERATIONAL",
      )
      place = described_class.new(payload("businessStatus" => "CLOSED_PERMANENTLY"))

      expect(place.attributes_for(venue)).to include(google_business_status: "CLOSED_PERMANENTLY")
    end

    # Identity is one fact, so a venue holding components but no place id keeps both as they are
    # rather than being told its address came from this place.
    it "treats identity as all or nothing" do
      venue = Lml::Venue.new(address_components: { "route" => "somewhere else" }, google_place_id: nil)

      attributes = described_class.new(payload).attributes_for(venue)

      expect(attributes).not_to have_key(:address_components)
      expect(attributes).not_to have_key(:google_place_id)
    end
  end

  describe "#closed_permanently?" do
    it "is true only for a permanently closed place" do
      expect(described_class.new(payload("businessStatus" => "CLOSED_PERMANENTLY"))).to be_closed_permanently
      expect(described_class.new(payload)).not_to be_closed_permanently
      expect(described_class.new(payload("businessStatus" => "CLOSED_TEMPORARILY"))).not_to be_closed_permanently
    end
  end
end
