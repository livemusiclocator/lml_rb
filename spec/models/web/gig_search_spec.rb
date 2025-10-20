# frozen_string_literal: true

require "rails_helper"

RSpec.describe Web::GigSearch do
  let(:default_location_object) do
    build(:lml_location, { internal_identifier: "melbourne", name: "Melbourne" })
  end

  let(:bendigo_location_object) do
    build(:lml_location, { internal_identifier: "bendigo", name: "Bendigo" })
  end

  let(:explorer_config) do
    instance_double(Web::ExplorerConfig,
                    locations: [default_location_object, bendigo_location_object],
                    default_location_object: default_location_object,)
  end

  describe "#title" do
    context "with no params (defaults)" do
      it "returns default title with default location" do
        search = described_class.new({}, explorer_config)
        expect(search.title).to eq("Live Music in Melbourne this week")
      end
    end

    context "with location param" do
      it "uses the specified location" do
        search = described_class.new({ location: "bendigo" }, explorer_config)
        expect(search.title).to eq("Live Music in Bendigo this week")
      end

      it "falls back to default location for unknown location" do
        search = described_class.new({ location: "unknown" }, explorer_config)
        expect(search.title).to eq("Live Music in Melbourne this week")
      end

      it "handles case-insensitive location matching" do
        search = described_class.new({ location: "BENDIGO" }, explorer_config)
        expect(search.title).to eq("Live Music in Bendigo this week")
      end
    end

    context "with date_range param" do
      [
        { date_range: "today", expected: "Live Music in Melbourne today" },
        { date_range: "tomorrow", expected: "Live Music in Melbourne tomorrow" },
        { date_range: "thisWeek", expected: "Live Music in Melbourne this week" },
        { date_range: "nextWeek", expected: "Live Music in Melbourne next week" },
        { date_range: "someday", expected: "Live Music in Melbourne" }, # unknown date_range
      ].each do |test_case|
        it "formats '#{test_case[:date_range]}' correctly" do
          search = described_class.new({ date_range: test_case[:date_range] }, explorer_config)
          expect(search.title).to eq(test_case[:expected])
        end
      end
    end

    context "with custom_date" do
      it "formats valid custom date" do
        search = described_class.new({
                                       date_range: "customDate",
                                       custom_date: "2025-10-24",
                                     }, explorer_config,)

        expect(search.title).to eq("Live Music in Melbourne on Friday 24th October 2025")
      end

      it "handles invalid custom date gracefully" do
        search = described_class.new({
                                       date_range: "customDate",
                                       custom_date: "not-a-date",
                                     }, explorer_config,)

        expect(search.title).to eq("Live Music in Melbourne")
      end

      it "ignores custom_date when date_range is not customDate" do
        search = described_class.new({
                                       date_range: "today",
                                       custom_date: "2024-12-25",
                                     }, explorer_config,)

        expect(search.title).to eq("Live Music in Melbourne today")
      end
    end

    context "with genre param" do
      it "formats single genre correctly" do
        search = described_class.new({ genre: ["Rock"] }, explorer_config)
        expect(search.title).to eq("Rock gigs in Melbourne this week")
      end

      it "formats two genres correctly" do
        search = described_class.new({ genre: %w[Rock Jazz] }, explorer_config)
        expect(search.title).to eq("Jazz and Rock gigs in Melbourne this week")
      end

      it "formats three genres correctly" do
        search = described_class.new({ genre: %w[Rock Jazz Blues] }, explorer_config)
        expect(search.title).to eq("Blues, Jazz and Rock gigs in Melbourne this week")
      end

      it "shows multiple genres text for more than 3 genres" do
        search = described_class.new({
                                       genre: %w[Rock Jazz Blues Pop Metal],
                                     }, explorer_config,)
        expect(search.title).to eq("Live Music (multiple genres) in Melbourne this week")
      end

      it "validates genres against GENRES constant (case-insensitive)" do
        search = described_class.new({ genre: %w[rock JAZZ InvalidGenre] }, explorer_config)
        expect(search.title).to eq("Jazz and Rock gigs in Melbourne this week")
      end

      it "removes duplicate genres (case-insensitive)" do
        search = described_class.new({ genre: %w[Rock rock ROCK] }, explorer_config)
        expect(search.title).to eq("Rock gigs in Melbourne this week")
      end

      it "sorts genres alphabetically (case-insensitive)" do
        search = described_class.new({ genre: %w[Rock Blues Jazz] }, explorer_config)
        expect(search.title).to eq("Blues, Jazz and Rock gigs in Melbourne this week")
      end

      it "handles empty genre array" do
        search = described_class.new({ genre: [] }, explorer_config)
        expect(search.title).to eq("Live Music in Melbourne this week")
      end
    end

    context "with all params combined" do
      it "formats complete title correctly" do
        all_params = { location: "bendigo", date_range: "tomorrow", genre: %w[Rock Jazz] }
        search = described_class.new(all_params, explorer_config)

        expect(search.title).to eq("Jazz and Rock gigs in Bendigo tomorrow")
      end
    end
  end
end
