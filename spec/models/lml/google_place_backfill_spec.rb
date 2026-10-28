# frozen_string_literal: true

require "rails_helper"

RSpec.describe Lml::GooglePlaceBackfill do
  def place(id: "place-espy", status: "OPERATIONAL")
    {
      "id" => id,
      "displayName" => { "text" => "Hotel Esplanade" },
      "formattedAddress" => "11 The Esplanade, St Kilda VIC 3182",
      "businessStatus" => status,
      "websiteUri" => "https://hotelesplanade.com.au",
      "timeZone" => { "id" => "Australia/Melbourne" },
      "location" => { "latitude" => -37.8676, "longitude" => 144.9756 },
      "addressComponents" => [{ "types" => ["postal_code"], "shortText" => "3182", "longText" => "3182" }],
    }
  end

  def gig_for(venue, date:)
    Lml::Gig.create!(venue: venue, name: "A gig", date: date)
  end

  def backfill(**options)
    Lml::GooglePlaceBackfill.new(places: @places, **options).call
  end

  before do
    @places = instance_double(Lml::GooglePlacesApiClient)
    allow(@places).to receive(:details).and_return(place)

    @venue = create(
      :lml_venue,
      name: "The Espy",
      google_place_id: "place-espy",
      address_components: { "postal_code" => "3182" },
    )
    gig_for(@venue, date: 6.months.ago.to_date)
  end

  it "keeps the whole answer for a venue with a gig in the last year" do
    expect(backfill).to eq("filled" => 1)

    expect(@places).to have_received(:details).with("place-espy")
    expect(@venue.reload.google_place).to eq(place)
  end

  it "fills gaps and refreshes the business status, as any lookup does" do
    allow(@places).to receive(:details).and_return(place(status: "CLOSED_PERMANENTLY"))
    @venue.update_columns(postcode: nil, time_zone: "Australia/Sydney")

    backfill

    expect(@venue.reload).to have_attributes(postcode: "3182", time_zone: "Australia/Sydney")
    expect(@venue).to be_closed_permanently
  end

  it "does not spend a request on a venue that already has the answer" do
    @venue.update_columns(google_place: place)

    expect(backfill).to eq({})
    expect(@places).not_to have_received(:details)
  end

  it "skips venues without a place id, or with a lookup's marker in its place" do
    @venue.update_columns(google_place_id: nil)
    gig_for(create(:lml_venue, name: "Vague", google_place_id: "ambiguous - 2 matches"), date: 1.month.ago.to_date)

    expect(backfill).to eq({})
    expect(@places).not_to have_received(:details)
  end

  it "leaves a venue whose last gig is outside the window alone" do
    expect(backfill(months: 3)).to eq({})
  end

  it "writes nothing when Google answers with a different id" do
    allow(@places).to receive(:details).and_return(place(id: "place-reissued"))

    expect(backfill).to eq("place id changed" => 1)
    expect(@venue.reload).to have_attributes(google_place: nil, google_place_id: "place-espy")
  end

  it "carries on through a venue that raises" do
    other = create(:lml_venue, name: "The Tote", google_place_id: "place-tote")
    gig_for(other, date: 1.month.ago.to_date)
    allow(@places).to receive(:details).with("place-tote").and_raise(Lml::GooglePlacesApiClient::Error, "404")

    expect(backfill).to eq("filled" => 1, "failed" => 1)
  end

  it "counts what a real run would spend, without spending it" do
    expect(backfill(dry_run: true)).to eq("places calls" => 1)
    expect(@places).not_to have_received(:details)
  end
end
