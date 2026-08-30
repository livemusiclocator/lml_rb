# frozen_string_literal: true

require "rails_helper"

RSpec.describe Lml::VenuePlaceLookup do
  def place(name, id: "placeespy")
    {
      "id" => id,
      "displayName" => { "text" => name },
      "formattedAddress" => "11 The Esplanade, St Kilda VIC 3182",
      "businessStatus" => "OPERATIONAL",
      "googleMapsUri" => "https://maps.google.com/?cid=espy",
      "timeZone" => { "id" => "Australia/Melbourne" },
      "location" => { "latitude" => -37.8676, "longitude" => 144.9756 },
      "addressComponents" => [
        { "types" => ["route"], "shortText" => "The Esplanade", "longText" => "The Esplanade" },
        { "types" => ["postal_code"], "shortText" => "3182", "longText" => "3182" },
      ],
    }
  end

  def lookup(venue, **options)
    described_class.call(venue, places: @places, **options)
  end

  before do
    @places = instance_double(Lml::GooglePlacesApiClient)
    allow(@places).to receive(:find).and_return("places" => [place("Hotel Esplanade")])

    @venue = create(:lml_venue, name: "The Espy", address: "11 The Esplanade, St Kilda")
  end

  describe "when exactly one place comes back" do
    it "records the place id" do
      expect(lookup(@venue)).to eq(described_class::MATCHED)
      expect(@venue.reload.google_place_id).to eq("placeespy")
    end

    it "asks for the venue's name and address, biased to Australia" do
      lookup(@venue)

      expect(@places).to have_received(:find).with("The Espy, 11 The Esplanade, St Kilda", region_code: "AU")
    end

    it "manages on the name alone where the venue has no address" do
      @venue.update!(address: nil)

      lookup(@venue)

      expect(@places).to have_received(:find).with("The Espy", region_code: "AU")
    end

    it "fills in a column the venue has nothing in" do
      lookup(@venue)

      expect(@venue.reload.latitude).to eq(-37.8676)
    end

    it "leaves a column somebody has already researched alone" do
      @venue.update!(latitude: -37.0, longitude: 144.0)

      lookup(@venue)

      expect(@venue.reload.latitude).to eq(-37.0)
    end

    it "records the business status even over an existing one, which is the point of it" do
      @venue.update!(google_business_status: "OPERATIONAL")

      allow(@places).to receive(:find).and_return(
        "places" => [place("Hotel Esplanade").merge("businessStatus" => "CLOSED_PERMANENTLY")],
      )

      lookup(@venue, force: true)

      expect(@venue.reload).to be_closed_permanently
    end
  end

  describe "when the lookup does not settle" do
    it "marks a venue Google has nothing for, so the empty answer is not lost" do
      allow(@places).to receive(:find).and_return("places" => [])

      expect(lookup(@venue)).to eq(described_class::NO_MATCH)
      expect(@venue.reload.google_place_id).to eq("no match")
    end

    it "treats a payload with no places key at all as nothing found" do
      allow(@places).to receive(:find).and_return({})

      expect(lookup(@venue)).to eq(described_class::NO_MATCH)
    end

    it "marks an ambiguous venue with how many candidates there were" do
      allow(@places).to receive(:find).and_return(
        "places" => [place("The Espy", id: "one"), place("Espy Kitchen", id: "two")],
      )

      expect(lookup(@venue)).to eq(described_class::AMBIGUOUS)
      expect(@venue.reload.google_place_id).to eq("ambiguous - 2 matches")
    end

    it "writes nothing else onto an ambiguous venue" do
      allow(@places).to receive(:find).and_return(
        "places" => [place("The Espy", id: "one"), place("Espy Kitchen", id: "two")],
      )

      lookup(@venue)

      expect(@venue.reload.address_components).to eq({})
      expect(@venue.latitude).to be_nil
    end

    it "records the marker on a venue too invalid to save normally" do
      @venue.update_column(:time_zone, "Mars/Olympus_Mons")
      allow(@places).to receive(:find).and_return("places" => [])

      lookup(@venue)

      expect(@venue.reload.google_place_id).to eq("no match")
    end
  end

  describe "not spending twice on the same question" do
    it "skips a venue that already has a place id" do
      @venue.update!(google_place_id: "placeespy")

      expect(lookup(@venue)).to eq(described_class::SKIPPED)
      expect(@places).not_to have_received(:find)
    end

    it "skips a venue whose last lookup found nothing, rather than asking again for free" do
      @venue.update!(google_place_id: "no match")

      expect(lookup(@venue)).to eq(described_class::SKIPPED)
      expect(@places).not_to have_received(:find)
    end

    it "asks again when forced" do
      @venue.update!(google_place_id: "no match")

      expect(lookup(@venue, force: true)).to eq(described_class::MATCHED)
      expect(@venue.reload.google_place_id).to eq("placeespy")
    end

    # Lml::Place holds identity back on a venue that has components already, on purpose: silently
    # repointing an established venue at a different place is worse than a stale one.
    it "refuses to repoint a venue that is genuinely resolved, even forced" do
      @venue.update!(google_place_id: "somewhereelse", address_components: { "route" => "Chapel Street" })

      expect(lookup(@venue, force: true)).to eq(described_class::MATCHED)
      expect(@venue.reload.google_place_id).to eq("somewhereelse")
    end
  end

  describe "telling a marker from an id" do
    it "reads a real place id as an id" do
      expect(create(:lml_venue, google_place_id: "ChIJ_abc-123").google_place_marker?).to be(false)
    end

    it "reads a marker as a marker" do
      expect(create(:lml_venue, google_place_id: "no match").google_place_marker?).to be(true)
    end

    it "reads a venue nobody has looked up as neither" do
      expect(create(:lml_venue).google_place_marker?).to be(false)
    end
  end
end
