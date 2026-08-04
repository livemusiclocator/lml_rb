# frozen_string_literal: true

require "rails_helper"
require "tzinfo"

RSpec.describe Lml::Timezone do
  describe ".convert" do
    it "expands a bare city name" do
      expect(described_class.convert("Melbourne")).to eq("Australia/Melbourne")
    end

    it "maps a deprecated iana name onto the modern one" do
      expect(described_class.convert("Australia/Victoria")).to eq("Australia/Melbourne")
      expect(described_class.convert("Australia/Queensland")).to eq("Australia/Brisbane")
      expect(described_class.convert("Australia/Yancowinna")).to eq("Australia/Broken_Hill")
    end

    it "leaves an identifier it knows nothing about as it is" do
      expect(described_class.convert("Europe/London")).to eq("Europe/London")
    end
  end

  describe ".canonical" do
    it "gives back one of our own zones unchanged" do
      expect(described_class.canonical("Australia/Melbourne")).to eq("Australia/Melbourne")
    end

    it "converts before deciding" do
      expect(described_class.canonical("Australia/Victoria")).to eq("Australia/Melbourne")
    end

    # A venue whose time_zone is outside CANONICAL_TIMEZONES cannot be saved, so callers taking a
    # zone from Google want nothing rather than something unusable.
    it "gives nothing for a zone we have no equivalent for" do
      expect(described_class.canonical("Europe/London")).to be_nil
      expect(described_class.canonical(nil)).to be_nil
      expect(described_class.canonical("total nonsense")).to be_nil
    end
  end

  # Google Places answers with an IANA identifier, so the set we have to cope with for an Australian
  # venue is exactly IANA's Australian zones. Every one of them has to land on a zone we accept,
  # otherwise a venue in that state silently falls back to the Melbourne default.
  describe "coverage of every australian iana zone" do
    it "maps all of them onto a canonical zone" do
      australian = TZInfo::Timezone.all_identifiers.grep(%r{\AAustralia/})

      unmapped = australian.reject { |identifier| described_class.canonical(identifier) }

      expect(unmapped).to be_empty
    end

    it "has an australian zone for every state and territory" do
      %w[
        Australia/Melbourne Australia/Sydney Australia/Brisbane Australia/Adelaide
        Australia/Perth Australia/Hobart Australia/Darwin Australia/Canberra
      ].each do |zone|
        expect(described_class.canonical(zone)).to eq(zone)
      end
    end
  end
end
