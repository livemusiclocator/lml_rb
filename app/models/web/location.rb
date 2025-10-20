# frozen_string_literal: true

module Web
  class Location < ApplicationRecord
    def self.ransackable_attributes(_auth_object = nil)
      %w[created_at id id_value internal_identifier latitude longitude map_zoom_level name
         seo_title_format_string updated_at visible_in_editions]
    end

    def venues
      Lml::Venue.where("LOWER(location) = LOWER(?)", internal_identifier)
    end

    validates :internal_identifier, presence: true, uniqueness: true
    validates :name, presence: true
    validates :latitude, presence: true,
                         numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }
    validates :longitude, presence: true,
                          numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }
    validates :map_zoom_level, presence: true,
                               numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 20 }

    # query by edition

    scope :by_internal_identifier, ->(internal_identifier) { where(internal_identifier: internal_identifier) }

    def in_location_text
      # TODO: set this via the model perhaps to avoid it coming out weird in future
      return "anywhere" if internal_identifier == "anywhere"

      "in #{name}"
    end

    private

    def ensure_visible_in_editions_is_array
      self.visible_in_editions = [] if visible_in_editions.nil?
      self.visible_in_editions = visible_in_editions.reject(&:blank?) if visible_in_editions.is_a?(Array)
    end

    def validate_visible_in_editions
      return if visible_in_editions.blank?

      # Ensure it's an array
      unless visible_in_editions.is_a?(Array)
        errors.add(:visible_in_editions, "must be an array")
        return
      end

      invalid_editions = visible_in_editions - AVAILABLE_EDITIONS
      return unless invalid_editions.any?

      errors.add(:visible_in_editions, "contains invalid editions: #{invalid_editions.join(", ")}")
    end
  end
end
