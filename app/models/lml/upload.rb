# frozen_string_literal: true

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
    # gigs.upload_id records which upload a gig arrived on, and Lml::Processors::Clipper reassigns
    # it every time a gig is processed again, so it is provenance rather than ownership. The column
    # has no foreign key, so nothing was stopping it dangling once an upload went. Nullify rather
    # than restrict: deleting a processed upload should not be gated on the gigs it happened to
    # create, and those gigs stand on their own afterwards.
    has_many :gigs,
             class_name: "Lml::Gig",
             foreign_key: :upload_id,
             inverse_of: :upload,
             dependent: :nullify

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
