# frozen_string_literal: true

require "rails_helper"

RSpec.describe Lml::VenueBackfill do
  def place(name, components, id: "place-espy", status: "OPERATIONAL")
    {
      "id" => id,
      "displayName" => { "text" => name },
      "formattedAddress" => "11 The Esplanade, St Kilda VIC 3182",
      "businessStatus" => status,
      "googleMapsUri" => "https://maps.google.com/?cid=espy",
      "timeZone" => { "id" => "Australia/Melbourne" },
      "location" => { "latitude" => -37.8676, "longitude" => 144.9756 },
      "addressComponents" => components.map do |type, text|
        { "types" => [type], "shortText" => text, "longText" => text }
      end,
    }
  end

  def esplanade_components
    {
      "street_number" => "11",
      "route" => "The Esplanade",
      "locality" => "St Kilda",
      "postal_code" => "3182",
      "country" => "AU",
    }
  end

  def gig_for(venue, date:, **attributes)
    Lml::Gig.create!(venue: venue, name: "A gig", date: date, **attributes)
  end

  def backfill(**options)
    described_class.new(places: @places, **options).call
  end

  before do
    @places = instance_double(Lml::GooglePlacesApiClient)
    allow(@places).to receive(:find).and_return(
      "places" => [place("Hotel Esplanade", esplanade_components)],
    )
  end

  describe "which venues it touches" do
    it "resolves a venue with a recent gig" do
      venue = create(:lml_venue, name: "The Espy")
      gig_for(venue, date: 1.month.ago.to_date)

      expect(backfill).to eq("filled" => 1)
      expect(venue.reload.address_components).to include(esplanade_components)
    end

    it "leaves a venue whose last gig is outside the window alone" do
      venue = create(:lml_venue, name: "Long Gone")
      gig_for(venue, date: 10.months.ago.to_date)

      expect(backfill).to eq({})
      expect(venue.reload.address_components).to eq({})
      expect(@places).not_to have_received(:find)
    end

    it "reaches further back when asked" do
      venue = create(:lml_venue, name: "Long Gone")
      gig_for(venue, date: 10.months.ago.to_date)

      expect(backfill(months: 12)).to eq("filled" => 1)
      expect(venue.reload.address_components).to include(esplanade_components)
    end

    it "counts an upcoming gig as active" do
      venue = create(:lml_venue, name: "The Espy")
      gig_for(venue, date: 2.weeks.from_now.to_date)

      expect(backfill).to eq("filled" => 1)
    end

    it "ignores hidden and draft gigs, which are not evidence of a real venue" do
      hidden = create(:lml_venue, name: "Hidden Only")
      draft = create(:lml_venue, name: "Draft Only")
      gig_for(hidden, date: 1.month.ago.to_date, hidden: true)
      gig_for(draft, date: 1.month.ago.to_date, status: "draft")

      expect(backfill).to eq({})
    end

    it "ignores a venue with no gigs at all" do
      create(:lml_venue, name: "Never Programmed")

      expect(backfill).to eq({})
    end

    it "does not spend a request on a venue that is already resolved" do
      venue = create(:lml_venue, name: "The Espy", address_components: esplanade_components)
      gig_for(venue, date: 1.month.ago.to_date)

      expect(backfill).to eq("already resolved" => 1)
      expect(@places).not_to have_received(:find)
    end
  end

  describe "what it writes" do
    before do
      @venue = create(:lml_venue, name: "The Espy", address: nil, time_zone: "Australia/Sydney")
      gig_for(@venue, date: 1.month.ago.to_date)
    end

    it "fills in the places data" do
      backfill

      expect(@venue.reload).to have_attributes(
        google_place_id: "place-espy",
        google_business_status: "OPERATIONAL",
        postcode: "3182",
        latitude: -37.8676,
        location_url: "https://maps.google.com/?cid=espy",
        address: "11 The Esplanade, St Kilda VIC 3182",
      )
    end

    it "does not overwrite a value the venue already had" do
      backfill

      # Somebody chose Sydney; a resolved time zone is not a good enough reason to argue.
      expect(@venue.reload.time_zone).to eq("Australia/Sydney")
    end

    it "records a venue that has closed down" do
      allow(@places).to receive(:find).and_return(
        "places" => [place("Hotel Esplanade", esplanade_components, status: "CLOSED_PERMANENTLY")],
      )

      backfill

      expect(@venue.reload).to be_closed_permanently
    end

    it "saves a venue whose other columns would fail validation" do
      @venue.update_columns(time_zone: nil)

      expect(backfill).to eq("filled" => 1)
      expect(@venue.reload.address_components).to include(esplanade_components)
    end
  end

  describe "a venue it cannot resolve" do
    before do
      @venue = create(:lml_venue, name: "Somewhere Vague")
      gig_for(@venue, date: 1.month.ago.to_date)
    end

    it "leaves it alone when places finds nothing" do
      allow(@places).to receive(:find).and_return({})

      expect(backfill).to eq("not found" => 1)
      expect(@venue.reload.address_components).to eq({})
    end

    it "leaves it alone when places finds more than one" do
      allow(@places).to receive(:find).and_return(
        "places" => [
          place("Espy Front Bar", esplanade_components),
          place("Espy Basement", esplanade_components),
        ],
      )

      expect(backfill).to eq("ambiguous" => 1)
      expect(@venue.reload.address_components).to eq({})
    end

    it "carries on through a venue that raises" do
      other = create(:lml_venue, name: "The Espy")
      gig_for(other, date: 1.month.ago.to_date)

      allow(@places).to receive(:find).with(/Vague/, region_code: "AU").and_raise("places is down")
      allow(@places).to receive(:find).with(/Espy/, region_code: "AU").and_return(
        "places" => [place("Hotel Esplanade", esplanade_components)],
      )

      expect(backfill).to eq("failed" => 1, "filled" => 1)
    end
  end

  describe "a dry run" do
    it "reports what a real run would cost without making a request" do
      recent = create(:lml_venue, name: "The Espy")
      done = create(:lml_venue, name: "Already Done", address_components: esplanade_components)
      stale = create(:lml_venue, name: "Long Gone")

      gig_for(recent, date: 1.month.ago.to_date)
      gig_for(done, date: 1.month.ago.to_date)
      gig_for(stale, date: 10.months.ago.to_date)

      expect(backfill(dry_run: true)).to eq(
        "venues in scope" => 2,
        "already resolved" => 1,
        "places calls" => 1,
      )

      expect(@places).not_to have_received(:find)
    end
  end
end
