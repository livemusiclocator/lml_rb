# frozen_string_literal: true

require "rails_helper"

describe Lml::Searchable do
  describe "Lml::Venue.search" do
    before do
      @tote = create(:lml_venue, name: "The Tote", location: "melbourne")
      @royal = create(:lml_venue, name: "Theatre Royal", location: "castlemaine")
    end

    it "matches on name" do
      expect(Lml::Venue.search("tote")).to eq([@tote])
    end

    it "ignores case" do
      expect(Lml::Venue.search("TOTE")).to eq([@tote])
    end

    it "matches on a label component the name does not contain" do
      expect(Lml::Venue.search("castlemaine")).to eq([@royal])
    end

    it "matches when every term matches something" do
      expect(Lml::Venue.search("tote melbourne")).to eq([@tote])
    end

    it "matches nothing when one term matches nothing" do
      expect(Lml::Venue.search("tote castlemaine")).to be_empty
    end

    it "returns everything for a blank query" do
      expect(Lml::Venue.search("")).to contain_exactly(@royal, @tote)
    end
  end

  describe "Lml::Act.search" do
    before do
      @amyl = create(:lml_act, name: "Amyl and the Sniffers", country: "Australia")
      @khruangbin = create(:lml_act, name: "Khruangbin", country: "USA")
    end

    it "matches on name" do
      expect(Lml::Act.search("sniffers")).to eq([@amyl])
    end

    it "matches on country" do
      expect(Lml::Act.search("usa")).to eq([@khruangbin])
    end
  end

  describe "Lml::Gig.search" do
    before do
      @tote = create(:lml_venue, name: "The Tote", location: "melbourne")
      @royal = create(:lml_venue, name: "Theatre Royal", location: "castlemaine")

      @gig = create(:lml_gig, name: "Sniffers Live", venue: @tote, date: "2026-09-01")
      @other_venue_gig = create(:lml_gig, name: "Sniffers Encore", venue: @royal, date: "2026-09-04")
      @hidden = create(:lml_gig, name: "Sniffers Secret", venue: @tote, date: "2026-09-02", hidden: true)
      @draft = create(:lml_gig, name: "Sniffers Sketch", venue: @tote, date: "2026-09-03", status: "draft")
    end

    it "matches on name" do
      expect(Lml::Gig.search("encore")).to eq([@other_venue_gig])
    end

    it "matches on the venue name" do
      expect(Lml::Gig.search("tote")).to eq([@gig])
    end

    it "matches on the date" do
      expect(Lml::Gig.search("2026-09-04")).to eq([@other_venue_gig])
    end

    it "excludes hidden gigs" do
      expect(Lml::Gig.search("sniffers")).not_to include(@hidden)
    end

    it "excludes draft gigs" do
      expect(Lml::Gig.search("sniffers")).not_to include(@draft)
    end

    it "scopes to a venue when given one" do
      expect(Lml::Gig.search("sniffers", venue_id: @royal.id)).to eq([@other_venue_gig])
    end

    it "orders by date" do
      expect(Lml::Gig.search("sniffers")).to eq([@gig, @other_venue_gig])
    end
  end
end
