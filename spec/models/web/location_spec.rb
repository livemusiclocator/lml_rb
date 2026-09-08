# frozen_string_literal: true

require "rails_helper"

RSpec.describe Web::Location, type: :model do
  describe "validations" do
    before do
      @location = build(:lml_location)
    end

    it "requires an internal identifier" do
      expect(@location).to validate_presence_of(:internal_identifier)
    end

    it "requires the internal identifier to be unique" do
      expect(@location).to validate_uniqueness_of(:internal_identifier)
    end

    it "requires a name" do
      expect(@location).to validate_presence_of(:name)
    end

    it "requires a latitude and a longitude" do
      expect(@location).to validate_presence_of(:latitude)
      expect(@location).to validate_presence_of(:longitude)
    end

    it "requires a map zoom level" do
      expect(@location).to validate_presence_of(:map_zoom_level)
    end

    it "keeps the latitude on the globe" do
      expect(@location).to validate_numericality_of(:latitude)
        .is_greater_than_or_equal_to(-90)
        .is_less_than_or_equal_to(90)
    end

    it "keeps the longitude on the globe" do
      expect(@location).to validate_numericality_of(:longitude)
        .is_greater_than_or_equal_to(-180)
        .is_less_than_or_equal_to(180)
    end

    it "keeps the map zoom level to a whole step Google will accept" do
      expect(@location).to validate_numericality_of(:map_zoom_level)
        .only_integer
        .is_greater_than(0)
        .is_less_than_or_equal_to(20)
    end
  end

  describe "factory" do
    it "has a valid factory" do
      expect(build(:lml_location)).to be_valid
    end
  end

  describe "associations" do
    before do
      @location = create(:lml_location, internal_identifier: "TEST001")
      @matching = create(:lml_venue, location: "TEST001")
      @differently_cased = create(:lml_venue, location: "test001")
      @elsewhere = create(:lml_venue, location: "OTHER")
    end

    it "finds venues with matching location (case insensitive)" do
      expect(@location.venues).to include(@matching, @differently_cased)
      expect(@location.venues).not_to include(@elsewhere)
    end
  end
end
