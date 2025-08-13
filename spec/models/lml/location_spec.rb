require 'rails_helper'

RSpec.describe Lml::Location, type: :model do
  describe 'validations' do
    subject { build(:lml_location) }
    it { should validate_presence_of(:internal_identifier) }
    it { should validate_uniqueness_of(:internal_identifier) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:latitude) }
    it { should validate_presence_of(:longitude) }
    it { should validate_presence_of(:map_zoom_level) }
    
    it { should validate_numericality_of(:latitude).is_greater_than_or_equal_to(-90).is_less_than_or_equal_to(90) }
    it { should validate_numericality_of(:longitude).is_greater_than_or_equal_to(-180).is_less_than_or_equal_to(180) }
    it { should validate_numericality_of(:map_zoom_level).only_integer.is_greater_than(0).is_less_than_or_equal_to(20) }
  end
  
  describe 'visible_in_editions validation' do
    let(:location) { build(:lml_location) }
    
    it 'accepts valid editions' do
      location.visible_in_editions = ["all", "geelong"]
      expect(location).to be_valid
    end
    
    it 'rejects invalid editions' do
      location.visible_in_editions = ["Invalid", "geelong"]
      expect(location).not_to be_valid
      expect(location.errors[:visible_in_editions]).to include("contains invalid editions: Invalid")
    end
    
    it 'allows empty editions' do
      location.visible_in_editions = []
      expect(location).to be_valid
    end
  end
  
  describe 'constants' do
    it 'has the correct available editions' do
      expect(Lml::Location::AVAILABLE_EDITIONS).to eq(["all", "geelong", "stKilda"])
    end
  end
  
  describe 'factory' do
    it 'has a valid factory' do
      location = build(:lml_location)
      expect(location).to be_valid
    end
  end
  describe 'associations' do
  let(:location) { create(:lml_location, internal_identifier: 'TEST001') }
  let!(:venue1) { create(:lml_venue, location: 'TEST001') }
  let!(:venue2) { create(:lml_venue, location: 'test001') } # case insensitive
  let!(:venue3) { create(:lml_venue, location: 'OTHER') }

  it 'finds venues with matching location (case insensitive)' do
    expect(location.venues).to include(venue1, venue2)
    expect(location.venues).not_to include(venue3)
  end
end
end
