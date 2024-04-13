module Lml
  class Upload < ApplicationRecord
    def self.ransackable_attributes(_auth_object = nil)
      %w[format source]
    end

    def self.ransackable_associations(_auth_object = nil)
      []
    end

    enum(
      :format,
      {
        clipper: "clipper",
        schema_org_events: "schema_org_events",
        venue_csv: "venue_csv",
        tm_api: "tm_api",
      },
      prefix: true,
    )

    validates :format, presence: true
    validates :content, presence: true

    belongs_to :venue, optional: true

    def venue_label
      venue&.label
    end

    def rescrape!
      case format
      when "schema_org_events"
        Lml::Processors::SchemaOrgEvents.new(self).scrape
      when "tm_api"
        Lml::Processors::TmApi.new(self).scrape
      end

      process!
    end

    def process!
      return unless valid?

      tz = venue.time_zone if venue
      tz = time_zone if tz.blank?
      Time.zone = tz unless tz.blank?

      case format
      when "clipper"
        Lml::Processors::Clipper.new(self).process!
      when "schema_org_events"
        Lml::Processors::SchemaOrgEvents.new(self).process!
      when "venue_csv"
        Lml::Processors::VenueCsv.new(self).process!
      when "tm_api"
        Lml::Processors::TmApi.new(self).process!
      end
    end

    scope :filter_by_source, ->(source) { where(source: source) }
  end
end
