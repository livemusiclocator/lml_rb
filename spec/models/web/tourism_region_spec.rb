# frozen_string_literal: true

require 'rails_helper'

describe Web::TourismRegion, type: :model do
  describe "::new" do
    context "without required fields" do
      before { @tourism_region = Web::TourismRegion.new }

      it "is invalid" do
        expect(@tourism_region.valid?).to be(false)
        expect(@tourism_region.errors.attribute_names).to eq([:name, :internal_identifier])
      end
    end
  end
end
