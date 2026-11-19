# frozen_string_literal: true

require 'rails_helper'

describe Lml::Venue, type: :model do
  describe "#destination" do
    before do
      @tourism_region = Web::TourismRegion.create!(name: "Melbourne", internal_identifier: "melbourne")
      @venue = Lml::Venue.create!(time_zone: "Australia/Melbourne", tourism_region: @tourism_region)
    end

    it "returns the tourism_region" do
      expect(@venue.destination).to eq("Melbourne")
    end

    context "the venue has no tourism_region" do
      before do
        @venue = Lml::Venue.create!(time_zone: "Australia/Melbourne")
      end

      it "returns nil" do
        expect(@venue.destination).to be_nil
      end
    end
  end

  describe "#suggest_tourism_region!" do
    before do
      [
        ["melbourne", "Melbourne" ],
        ["gippsland", "Gippsland" ],
        ["phillip_island", "Phillip Island" ],
      ].each do |internal_identifier, name|
        create(:web_tourism_region, name: name, internal_identifier: internal_identifier)
      end
    end

    context "the lga straddles regions" do
      before do
        @venue_mitchell = Lml::Venue.create!(time_zone: "Australia/Melbourne", lga: "Mitchell")
        @venue_murrindindi = Lml::Venue.create!(time_zone: "Australia/Melbourne", lga: "Murrindindi")
      end

      it "lets a human decide" do
        @venue_mitchell.suggest_tourism_region!
        @venue_murrindindi.suggest_tourism_region!

        expect(@venue_mitchell.tourism_region).to be_nil
        expect(@venue_murrindindi.tourism_region).to be_nil
      end
    end

    context "the lga is Bass Coast Shire" do
      before do
        @venue_phillip_island = Lml::Venue.create!(time_zone: "Australia/Melbourne", lga: "Bass Coast Shire", location: "Phillip Island")
        @venue_san_remo = Lml::Venue.create!(time_zone: "Australia/Melbourne", lga: "Bass Coast Shire", location: "San Remo")
        @venue_wonthaggi = Lml::Venue.create!(time_zone: "Australia/Melbourne", lga: "Bass Coast Shire", location: "Wonthaggi")
        @venue_inverloch = Lml::Venue.create!(time_zone: "Australia/Melbourne", lga: "Bass Coast Shire", location: "Inverloch")
        @venue_kilcunda = Lml::Venue.create!(time_zone: "Australia/Melbourne", lga: "Bass Coast Shire", location: "Kilcunda")
        @venue_cape_patterson = Lml::Venue.create!(time_zone: "Australia/Melbourne", lga: "Bass Coast Shire", location: "Cape Patterson")
      end

      it "splits according to Visit Victoria" do
        @venue_phillip_island.suggest_tourism_region!
        @venue_san_remo.suggest_tourism_region!
        @venue_wonthaggi.suggest_tourism_region!
        @venue_inverloch.suggest_tourism_region!
        @venue_kilcunda.suggest_tourism_region!
        @venue_cape_patterson.suggest_tourism_region!

        expect(@venue_phillip_island.tourism_region.name).to eq("Phillip Island")
        expect(@venue_san_remo.tourism_region.name).to eq("Phillip Island")
        expect(@venue_wonthaggi.tourism_region.name).to eq("Gippsland")
        expect(@venue_inverloch.tourism_region.name).to eq("Gippsland")
        expect(@venue_kilcunda.tourism_region.name).to eq("Gippsland")
        expect(@venue_cape_patterson.tourism_region.name).to eq("Gippsland")
      end
    end

    context "venue has no lga" do
      before do
        @venue = Lml::Venue.create!(time_zone: "Australia/Melbourne")
      end

      it "lets a human decide" do
        @venue.suggest_tourism_region!

        expect(@venue.tourism_region).to be_nil
      end
    end

    context "the lga sits wholly in one region" do
      before do
        @venue = Lml::Venue.create!(time_zone: "Australia/Melbourne", lga: "City of Yarra")
      end

      it "chooses the correct region" do
        @venue.suggest_tourism_region!

        expect(@venue.tourism_region.name).to eq("Melbourne")
      end
    end
  end
end
