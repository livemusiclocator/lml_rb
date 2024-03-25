# frozen_string_literal: true

describe Eventfinda::Location do
  subject { Eventfinda::Location.new({ point: { lat: 0, lng: 20 } }) }
  let(:result) { JSON.parse(subject.to_schema_org_builder.target!) }

  it "createas a schema org object of type Place" do
    expect(result).to include("@type" => "Place")
  end

  it "populates basic information relating to the location" do
    subject.name = "The Moon"
    subject.summary = "Earth's Orbit"
    expect(result).to include("name" => "The Moon", "address" => "Earth's Orbit")
  end
  it "adds links back to original location using url-slug" do
    subject.url_slug = "the-moon"
    expect(result).to include("sameAs" => "https://www.eventfinda.com.au/venue/the-moon")
  end
  it "adds a geo for the lat/long point data" do
    subject.point.lat = 51.4419
    subject.point.lng = 0.3708

    expect(result["geo"]).to include("@type" => "GeoCoordinates", "latitude" => 51.4419, "longitude" => 0.37080)
  end
end
