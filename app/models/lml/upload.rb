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

      # Clipper assigns Time.zone per entry and never puts it back, and Time.zone
      # is thread local - Rails does not reset it between requests. Without this,
      # processing an upload leaves every later request served by that thread
      # rendering times in the last venue's zone. use_zone restores what was
      # there when the block ends.
      Time.use_zone(Time.zone) do
        Lml::Processors::Clipper.new(self).process!
      end
    end

    scope :filter_by_source, ->(source) { where(source: source) }
  end
end
