module Lml
  class Upload < ApplicationRecord
    def self.ransackable_attributes(_auth_object = nil)
      %w[format source]
    end

    def self.ransackable_associations(_auth_object = nil)
      []
    end

    validates :content, presence: true

    belongs_to :venue, optional: true

    def venue_label
      venue&.label
    end

    def process!
      return unless valid?

      tz = venue.time_zone if venue
      tz = time_zone if tz.blank?
      Time.zone = tz unless tz.blank?

      Lml::Processors::Clipper.new(self).process!
    end

    scope :filter_by_source, ->(source) { where(source: source) }
  end
end
