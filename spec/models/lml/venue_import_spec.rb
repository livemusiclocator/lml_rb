# frozen_string_literal: true

require "rails_helper"

RSpec.describe Lml::VenueImport do
  # A place as the Places API returns it, trimmed to the fields the importer reads.
  def place(name, components, id: "place-espy", formatted: "11 The Esplanade, St Kilda VIC 3182")
    {
      "id" => id,
      "displayName" => { "text" => name },
      "formattedAddress" => formatted,
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
      "administrative_area_level_1" => "VIC",
      "postal_code" => "3182",
      "country" => "AU",
    }
  end

  def import
    described_class.new(sheet: @sheet, worksheet: "venues", places: @places).call
  end

  before do
    @rows = []
    @writes = []

    @sheet = instance_double(Lml::Sheet, ensure_headers: nil)
    allow(@sheet).to receive(:rows) { @rows }
    allow(@sheet).to receive(:write_row) { |**args| @writes << args }

    @places = instance_double(Lml::GooglePlacesApiClient)
    allow(@places).to receive(:find).and_return(
      "places" => [place("Hotel Esplanade", esplanade_components)],
    )
  end

  it "adds the output columns before writing any rows" do
    import

    expect(@sheet).to have_received(:ensure_headers).with(
      worksheet: "venues",
      headers: %w[venue_id import_status],
    )
  end

  describe "a row with no matching venue" do
    before do
      @rows = [{ "name" => "The Espy", "address" => "11 The Esplanade St Kilda", "location" => "stkilda" }]
    end

    it "creates the venue" do
      expect { import }.to change(Lml::Venue, :count).by(1)

      expect(Lml::Venue.last).to have_attributes(
        name: "The Espy",
        location: "stkilda",
        address: "11 The Esplanade St Kilda",
        time_zone: "Australia/Melbourne",
      )
    end

    it "populates the structured address data from places" do
      import

      expect(Lml::Venue.last).to have_attributes(
        postcode: "3182",
        latitude: -37.8676,
        longitude: 144.9756,
        google_place_id: "place-espy",
      )

      expect(Lml::Venue.last.address_components).to include(esplanade_components)
    end

    it "writes the new id and colours the row done" do
      import

      expect(@writes).to eq(
        [{
          worksheet: "venues",
          index: 0,
          cells: { "import_status" => "created", "venue_id" => Lml::Venue.last.id },
          colour: :done,
        }],
      )
    end

    it "queries places with the name and address, biased to australia" do
      import

      expect(@places).to have_received(:find).with(
        "The Espy, 11 The Esplanade St Kilda",
        region_code: "AU",
      )
    end

    it "falls back to the address google resolved when the sheet has none" do
      @rows = [{ "name" => "The Espy", "address" => nil }]

      import

      expect(Lml::Venue.last.address).to eq("11 The Esplanade, St Kilda VIC 3182")
    end
  end

  describe "a row whose venue already exists" do
    it "matches on the resolved address components rather than creating a duplicate" do
      venue = create(:lml_venue, name: "Hotel Esplanade", address_components: esplanade_components)
      @rows = [{ "name" => "The Espy", "address" => "The Esplanade, St Kilda VIC 3182" }]

      expect { import }.not_to change(Lml::Venue, :count)

      expect(@writes.first[:cells]).to eq("import_status" => "matched", "venue_id" => venue.id)
      expect(@writes.first[:colour]).to eq(:done)
    end

    it "matches on name where no venue has components yet, and backfills them" do
      venue = create(:lml_venue, name: "The Espy")
      @rows = [{ "name" => "the espy " }]

      expect { import }.not_to change(Lml::Venue, :count)

      expect(@writes.first[:cells]).to include("venue_id" => venue.id)
      expect(venue.reload.address_components).to include(esplanade_components)
      expect(venue.google_place_id).to eq("place-espy")
    end

    it "leaves the components of a venue that already has them alone" do
      venue = create(:lml_venue, name: "Hotel Esplanade", address_components: { "route" => "somewhere else" })
      @rows = [{ "name" => "Hotel Esplanade" }]

      import

      expect(venue.reload.address_components).to eq("route" => "somewhere else")
    end

    it "does not match a venue in the same building carrying an extra subpremise" do
      create(
        :lml_venue,
        name: "Gershwin Room",
        address_components: esplanade_components.merge("subpremise" => "2"),
      )
      @rows = [{ "name" => "The Espy" }]

      expect { import }.not_to change(Lml::Venue, :count)

      expect(@writes.first[:cells]["import_status"]).to eq("same building - Gershwin Room")
      expect(@writes.first[:colour]).to eq(:attention)
    end
  end

  describe "a row that has already been imported" do
    it "is left completely alone" do
      @rows = [{ "name" => "The Espy", "venue_id" => "already-here" }]

      expect { import }.not_to change(Lml::Venue, :count)

      expect(@writes).to eq([{ worksheet: "venues", index: 0, cells: {}, colour: nil }])
      expect(@places).not_to have_received(:find)
    end

    it "is counted as already imported" do
      @rows = [{ "name" => "The Espy", "venue_id" => "already-here" }]

      expect(import).to eq("already imported" => 1)
    end
  end

  describe "a row the importer cannot decide" do
    it "is coloured for attention when the row has no name" do
      @rows = [{ "name" => nil, "address" => "somewhere" }]

      expect { import }.not_to change(Lml::Venue, :count)

      expect(@writes.first).to include(cells: { "import_status" => "no name", "venue_id" => nil }, colour: :attention)
    end

    it "is coloured for attention when places finds nothing" do
      allow(@places).to receive(:find).and_return({})
      @rows = [{ "name" => "Nowhere At All" }]

      expect { import }.not_to change(Lml::Venue, :count)

      expect(@writes.first[:cells]["import_status"]).to eq("not found")
    end

    it "names the candidates when places finds more than one" do
      allow(@places).to receive(:find).and_return(
        "places" => [
          place("Esplanade Hotel", esplanade_components),
          place("Espy Kitchen", esplanade_components),
        ],
      )
      @rows = [{ "name" => "Espy" }]

      expect { import }.not_to change(Lml::Venue, :count)

      expect(@writes.first[:cells]["import_status"]).to eq(
        "ambiguous - 2 places: Esplanade Hotel | Espy Kitchen",
      )
    end

    it "names the venues when more than one already matches" do
      create(:lml_venue, name: "Espy Basement", address_components: esplanade_components)
      create(:lml_venue, name: "Espy Public Bar", address_components: esplanade_components)
      @rows = [{ "name" => "The Espy" }]

      expect { import }.not_to change(Lml::Venue, :count)

      expect(@writes.first[:cells]["import_status"]).to eq(
        "several venues - Espy Basement | Espy Public Bar",
      )
    end

    it "does not match every venue when google resolved no address components" do
      create(:lml_venue, name: "Somewhere Else", address_components: {})
      allow(@places).to receive(:find).and_return("places" => [place("The Espy", {})])
      @rows = [{ "name" => "The Espy" }]

      expect { import }.to change(Lml::Venue, :count).by(1)
    end
  end

  describe "a row that raises" do
    before do
      @rows = [{ "name" => "Explodes" }, { "name" => "The Espy" }]

      allow(@places).to receive(:find).with(/Explodes/, region_code: "AU").and_raise("places is down")
      allow(@places).to receive(:find).with(/Espy/, region_code: "AU").and_return(
        "places" => [place("Hotel Esplanade", esplanade_components)],
      )
    end

    it "puts the reason in the sheet rather than only the logs" do
      import

      expect(@writes.first[:cells]["import_status"]).to eq("failed - places is down")
      expect(@writes.first[:colour]).to eq(:attention)
    end

    it "still processes every row after it" do
      expect { import }.to change(Lml::Venue, :count).by(1)

      expect(@writes.last[:cells]["import_status"]).to eq("created")
    end
  end

  # Places bills per request, so what a second run costs is entirely down to which rows it asks
  # about again. Re-running is the normal way to work through the rows that need attention.
  describe "running it a second time" do
    # Standing in for the sheet: what the first run wrote is what the second run reads back.
    def rerun
      @writes.each do |write|
        @rows[write[:index]] = @rows[write[:index]].merge(write[:cells].compact)
      end
      @writes.clear

      import
    end

    it "does not ask places about a row it has already resolved" do
      @rows = [{ "name" => "The Espy" }]

      import
      expect(@places).to have_received(:find).once

      expect(rerun).to eq("already imported" => 1)
      expect(@places).to have_received(:find).once
    end

    it "does not ask places about a row it matched to an existing venue" do
      create(:lml_venue, name: "Hotel Esplanade", address_components: esplanade_components)
      @rows = [{ "name" => "The Espy" }]

      import
      expect(rerun).to eq("already imported" => 1)

      expect(@places).to have_received(:find).once
    end

    # No venue_id was written, so there is nothing to skip on. This is deliberate - the point of
    # re-running is to pick up rows whose address someone has since corrected - but it does mean a
    # sheet left full of yellow rows costs a request per yellow row every time it is run.
    it "asks again about a row it could not resolve" do
      allow(@places).to receive(:find).and_return({})
      @rows = [{ "name" => "Nowhere At All" }]

      import
      expect(rerun).to eq("not found" => 1)

      expect(@places).to have_received(:find).twice
    end

    it "asks only about the rows that are still unresolved" do
      allow(@places).to receive(:find).with(/Espy/, region_code: "AU").and_return(
        "places" => [place("Hotel Esplanade", esplanade_components)],
      )
      allow(@places).to receive(:find).with(/Nowhere/, region_code: "AU").and_return({})

      @rows = [{ "name" => "The Espy" }, { "name" => "Nowhere At All" }]

      import
      expect(rerun).to eq("already imported" => 1, "not found" => 1)

      expect(@places).to have_received(:find).with(/Espy/, region_code: "AU").once
      expect(@places).to have_received(:find).with(/Nowhere/, region_code: "AU").twice
    end
  end

  it "returns what each row came to" do
    create(:lml_venue, name: "Hotel Esplanade", address_components: esplanade_components)

    allow(@places).to receive(:find).with(/Espy/, region_code: "AU").and_return(
      "places" => [place("Hotel Esplanade", esplanade_components)],
    )
    allow(@places).to receive(:find).with(/New Venue/, region_code: "AU").and_return(
      "places" => [place("Some New Venue", { "route" => "Brunswick Street", "country" => "AU" }, id: "place-new")],
    )

    @rows = [
      { "name" => "The Espy" },
      { "name" => "Some New Venue" },
      { "name" => "Done Already", "venue_id" => "already-here" },
      { "name" => nil },
    ]

    expect(import).to eq(
      "matched" => 1,
      "created" => 1,
      "already imported" => 1,
      "no name" => 1,
    )
  end
end
