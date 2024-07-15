module Lml
  class Upload < ApplicationRecord
    def self.ransackable_attributes(_auth_object = nil)
      %w[
        source
        venue_id
      ]
    end

    def self.ransackable_associations(_auth_object = nil)
      []
    end

    belongs_to :venue, optional: true

    def venue_label
      venue&.label
    end

    def process!
      return if content.blank?

      Lml::Processors::Clipper.new(self).process!
    end

    scope :filter_by_source, ->(source) { where(source: source) }
  end
end
