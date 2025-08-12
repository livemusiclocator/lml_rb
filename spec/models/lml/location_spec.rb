require "rails_helper"

RSpec.describe Lml::Location, type: :model do
  describe "validations" do
    it { should validate_presence_of(:internal_identifier) }
    it { should validate_uniqueness_of(:internal_identifier) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:latitude) }
    it { should validate_presence_of(:longitude) }

    it { should validate_numericality_of(:latitude).is_greater_than_or_equal_to(-90).is_less_than_or_equal_to(90) }
    it { should validate_numericality_of(:longitude).is_greater_than_or_equal_to(-180).is_less_than_or_equal_to(180) }
  end

  describe "factory" do
    it "has a valid factory" do
      location = build(:lml_location)
      expect(location).to be_valid
    end
  end
end
