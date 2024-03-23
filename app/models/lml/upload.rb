module Lml
  class Upload < ApplicationRecord
    def self.ransackable_attributes(_auth_object = nil)
      %w[format source]
    end

    def self.ransackable_associations(_auth_object = nil)
      []
    end

    enum :format, { clipper: "clipper", schema_org_events: "schema_org_events" }, prefix: true

    validates :format, presence: true
    validates :source, presence: true
    validates :content, presence: true
    validates :time_zone, presence: true

    belongs_to :venue, optional: true

    def venue_label
      venue&.label
    end

    def process!
      return unless valid?

      Time.zone = time_zone

      case format
      when "clipper"
        Lml::Processors::Clipper.new(self).process!
      when "schema_org_events"
        Lml::Processors::SchemaOrgEvents.new(self).process!
      end
    end
  end
end
