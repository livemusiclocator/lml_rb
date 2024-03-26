require "open-uri"

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
      },
      prefix: true,
    )

    validates :format, presence: true
    validates :source, presence: true
    validates :content, presence: true

    belongs_to :venue, optional: true

    def venue_label
      venue&.label
    end

    def rescrape!
      docs = []
      page = Nokogiri::HTML(URI.open(source))
      page.css('script[type="application/ld+json"]').each do |ld|
        html_content = ld.inner_html.strip
        doc = JSON.parse(html_content)
        if html_content[0] == "["
          docs += doc
        else
          docs << doc
        end
      end

      update!(content: JSON.pretty_generate(docs))

      process!
    end

    def process!
      return unless valid?

      Time.zone = time_zone unless time_zone.blank?

      case format
      when "clipper"
        Lml::Processors::Clipper.new(self).process!
      when "schema_org_events"
        Lml::Processors::SchemaOrgEvents.new(self).process!
      when "venue_csv"
        Lml::Processors::VenueCsv.new(self).process!
      end
    end

    scope :filter_by_source, ->(source) { where(source: source) }
  end
end
