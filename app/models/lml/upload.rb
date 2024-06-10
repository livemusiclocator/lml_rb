module Lml
  class Upload < ApplicationRecord
    def self.ransackable_attributes(_auth_object = nil)
      %w[source]
    end

    def self.ransackable_associations(_auth_object = nil)
      []
    end

    validates :content, presence: true
    belongs_to :venue

    def venue_label
      venue&.label
    end

    def process!
      return unless valid?

      Lml::Processors::Clipper.new(self).process!
    end

    scope :filter_by_source, ->(source) { where(source: source) }
  end
end
