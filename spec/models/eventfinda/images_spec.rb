# frozen_string_literal: true

describe Eventfinda::Images do
  let(:result) { subject.to_schema_org_builder }

  context "at least one primary image is present" do
    subject { Eventfinda::Images.new(images: [{ is_primary: true, original_url: "https://cdn/image.jpg" }]) }
    # TODO: do we want to pick one of the transformed images (different sizes)
    it "adds an image url" do
      expect(result).to eq("https://cdn/image.jpg")
    end
  end

  context "images empty" do
    subject { Eventfinda::Images.new({ :@count => 0, images: [] }) }
    it "returns nothing" do
      expect(result).to be_nil
    end
  end
end
