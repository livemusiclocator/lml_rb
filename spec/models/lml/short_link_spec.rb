# frozen_string_literal: true

require "rails_helper"

describe Lml::ShortLink do
  before do
    @uuid = "3f9a2c1e-7b4d-4e2a-9c1f-0a8b6d5e4f3c"
  end

  it "makes an eight character code from the start of a uuid" do
    expect(described_class.code(@uuid)).to match(/\A[0-9A-Za-z]{8}\z/)
  end

  it "decodes a code to a range holding the uuid it came from" do
    expect(described_class.id_range(described_class.code(@uuid))).to cover(@uuid)
  end

  it "gives uuids that differ only after the first 47 bits the same code" do
    expect(described_class.code("3f9a2c1e-7b4d-0000-0000-000000000000"))
      .to eq(described_class.code("3f9a2c1e-7b4d-ffff-ffff-ffffffffffff"))
  end

  it "copes with the lowest and highest uuids" do
    %w[00000000-0000-0000-0000-000000000000 ffffffff-ffff-ffff-ffff-ffffffffffff].each do |uuid|
      expect(described_class.id_range(described_class.code(uuid))).to cover(uuid)
    end
  end

  it "rejects anything that is not a code" do
    ["", "short", "toolong12", "has-dash", "zzzzzzzz"].each do |code|
      expect(described_class.id_range(code)).to be_nil
    end
  end

  it "makes a url for each kind of record" do
    gig = create(:lml_gig)

    expect(gig.short_url).to eq("https://lml.live/g/#{described_class.code(gig.id)}")
    expect(gig.venue.short_url).to start_with("https://lml.live/v/")
  end
end
