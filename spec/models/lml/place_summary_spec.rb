# frozen_string_literal: true

require "rails_helper"

RSpec.describe Lml::PlaceSummary do
  def summary(place = {}, **venue)
    Lml::PlaceSummary.new(Lml::Venue.new(google_place: @place.merge(place), **venue))
  end

  before do
    @place = {
      "id" => "place-tote",
      "displayName" => { "text" => "The Tote" },
      "shortFormattedAddress" => "67-71 Johnston St, Collingwood",
      "websiteUri" => "https://thetotehotel.com/",
      "nationalPhoneNumber" => "(03) 9419 5320",
      "googleMapsUri" => "https://maps.google.com/?cid=1&g_mp=x",
      "primaryType" => "live_music_venue",
      "primaryTypeDisplayName" => { "text" => "Live Music Venue" },
      "types" => %w[live_music_venue pub event_venue bar point_of_interest establishment],
    }
  end

  it "is not there for a venue without google's answer" do
    expect(Lml::PlaceSummary.new(Lml::Venue.new)).not_to be_present
  end

  it "says what kind of place it is, without the types that say nothing" do
    expect(summary.kind).to eq("Live Music Venue")
    expect(summary.types).to eq(["pub", "event venue", "bar"])
  end

  it "picks the day's opening hours, Monday first as Google lists them" do
    hours = %w[Monday Tuesday Wednesday Thursday Friday Saturday Sunday].map { |day| "#{day}: 4:00 PM – 1:00 AM" }
    place = summary({ "regularOpeningHours" => { "weekdayDescriptions" => hours } })

    expect(place.hours_on(Date.new(2026, 10, 26))).to start_with("Monday")
    expect(place.hours_on(Date.new(2026, 11, 1))).to start_with("Sunday")
  end

  it "splits what is wheelchair accessible from what is not, and leaves out the unknown" do
    access = summary(
      { "accessibilityOptions" => { "wheelchairAccessibleEntrance" => true, "wheelchairAccessibleParking" => false } },
    ).accessibility

    expect(access).to eq(accessible: ["entrance"], not_accessible: ["parking"])
  end

  it "lists where google disagrees with the venue" do
    differences = summary(name: "Tote", address: "71 Johnston St", website: nil).differences

    expect(differences).to include(
      name: ["The Tote", "Tote"],
      address: ["67-71 Johnston St, Collingwood", "71 Johnston St"],
      website: ["https://thetotehotel.com/", nil],
    )
  end

  it "takes the long form of google's address as agreeing, and a missing map link as no disagreement" do
    differences = summary(
      { "formattedAddress" => "67-71 Johnston St, Collingwood VIC 3066, Australia" },
      name: "The Tote",
      address: "67-71 Johnston St, Collingwood VIC 3066, Australia",
      website: "https://thetotehotel.com",
      phone: "(03) 9419 5320",
      location_url: nil,
    ).differences

    expect(differences).to eq({})
  end

  it "does not count the same website or phone number written differently" do
    differences = summary(
      name: "The Tote",
      address: "67-71 Johnston St, Collingwood",
      website: "https://TheToteHotel.com",
      phone: "03 9419 5320",
      location_url: "https://maps.google.com/?cid=1",
    ).differences

    expect(differences).to eq({})
  end
end
