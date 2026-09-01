# frozen_string_literal: true

require "rails_helper"

describe Lml::CoverageStats do
  before do
    @today = Date.new(2026, 9, 1)

    %w[anywhere melbourne stkilda bendigo brisbane].each do |identifier|
      Web::Location.create!(
        internal_identifier: identifier,
        name: identifier.titleize,
        latitude: -37.8,
        longitude: 144.9,
      )
    end
    Web::ExplorerConfig.create!(
      edition_id: "main",
      selectable_locations: %w[anywhere melbourne stkilda bendigo brisbane],
    )

    @melbourne = create(:lml_venue, name: "The Tote", location: "Melbourne")
    @stkilda = create(:lml_venue, name: "The Espy", location: "stkilda")
    @bendigo = create(:lml_venue, name: "The Golden", location: "bendigo")
    @brisbane = create(:lml_venue, name: "The Zoo", location: "brisbane")
    @quiet = create(:lml_venue, name: "The Silent", location: "Melbourne")
    @stranded = create(:lml_venue, name: "The Lost", location: "St Kilda")
  end

  def stats = described_class.new(today: @today)

  def gig_at(venue, date, **attributes)
    create(:lml_gig, venue: venue, date: date, **attributes)
  end

  describe "regions" do
    it "covers the publicly selectable locations, and not the pseudo location" do
      expect(stats.regions.map(&:identifier)).to contain_exactly("melbourne", "stkilda", "bendigo", "brisbane")
    end

    it "orders Victorian regions first, biggest first, so a total follows its own rows" do
      2.times { |n| create(:lml_venue, name: "Another Golden #{n}", location: "bendigo") }

      expect(stats.regions.map(&:victorian?)).to eq([true, true, true, false])
      expect(stats.regions.take(3).map(&:identifier)).to eq(["bendigo", "melbourne", "stkilda"])
    end

    it "names a region from its location record" do
      expect(stats.regions.find { |region| region.identifier == "stkilda" }.name).to eq("Stkilda")
    end

    it "counts venues whatever case the location column was typed in" do
      expect(stats.regions.find { |region| region.identifier == "melbourne" }.venues).to eq(2)
    end

    it "reports zero for a live region that has no venues yet" do
      Web::Location.create!(internal_identifier: "geelong", name: "Geelong", latitude: -38.1, longitude: 144.3)
      Web::ExplorerConfig.find_by(edition_id: "main").update!(
        selectable_locations: %w[anywhere melbourne geelong],
      )

      geelong = stats.regions.find { |region| region.identifier == "geelong" }
      expect([geelong.venues, geelong.active, geelong.gigs]).to eq([0, 0, 0])
    end
  end

  describe "victorian totals" do
    it "leaves an interstate region out of the totals but keeps its row" do
      expect(stats.venues).to eq(4)
      expect(stats.regions.find { |region| region.identifier == "brisbane" }.venues).to eq(1)
    end

    it "counts a venue as active when it has a visible gig in the period" do
      gig_at(@melbourne, @today - 30)
      gig_at(@bendigo, @today - 300)

      expect(stats.active_venues).to eq(2)
      expect(stats.recently_active_venues).to eq(1)
    end

    it "ignores hidden and draft gigs" do
      gig_at(@melbourne, @today - 30, hidden: true)
      gig_at(@stkilda, @today - 30, status: "draft")

      expect(stats.active_venues).to be_zero
      expect(stats.gigs).to be_zero
    end

    it "averages the period's gigs over its weeks" do
      104.times { |n| gig_at(@melbourne, @today - 1 - n) }

      expect(stats.gigs).to eq(104)
      expect(stats.gigs_per_week).to eq(2.0)
    end

    it "excludes gigs outside the period at either end" do
      gig_at(@melbourne, @today)
      gig_at(@melbourne, @today - (52 * 7) - 1)

      expect(stats.gigs).to be_zero
    end
  end

  describe "unserved locations" do
    it "lists a location no live region serves, commonest first" do
      create(:lml_venue, name: "The Other Lost", location: "st kilda")

      expect(stats.unserved_locations).to eq([["st kilda", 2]])
      expect(stats.unserved_venues).to eq(2)
    end

    it "lists only the head of a long tail, and says how much it left out" do
      12.times { |n| create(:lml_venue, name: "Venue #{n}", location: "town #{n}") }

      expect(stats.unserved_locations.size).to eq(13)
      expect(stats.listed_unserved_locations.size).to eq(10)
      expect(stats.unlisted_unserved_locations).to eq(3)
    end

    it "leaves nothing unlisted when the tail is short" do
      expect(stats.unlisted_unserved_locations).to be_zero
    end

    it "ignores venues with no location at all" do
      create(:lml_venue, name: "The Homeless", location: nil)
      create(:lml_venue, name: "The Blank", location: "")

      expect(stats.unserved_locations).to eq([["st kilda", 1]])
    end
  end
end
