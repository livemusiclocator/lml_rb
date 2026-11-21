# frozen_string_literal: true

require 'rails_helper'

describe Lml::Venue, type: :model do
  before do
    @tourism_region = Web::TourismRegion.create!(name: "Melbourne", internal_identifier: "melbourne")
    @venue = Lml::Venue.create!(time_zone: "Australia/Melbourne", tourism_region: @tourism_region)
  end

  describe "#destination" do
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
end
