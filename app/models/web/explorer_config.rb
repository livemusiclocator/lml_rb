# frozen_string_literal: true

# app/models/web/explorer_config.rb
module Web
  class ExplorerConfig < ApplicationRecord
    has_many :series_themes, class_name: "Web::SeriesTheme", dependent: :destroy
    accepts_nested_attributes_for :series_themes

    # Serialize selectable_locations as JSON array
    attribute :selectable_locations, :json, default: -> { [] }
    attr_readonly :edition_id
    validates :edition_id, uniqueness: true, presence: true

    def self.ransackable_attributes(_auth_object = nil)
      %w[allow_all_locations created_at default_location edition_id id id_value
         selectable_locations updated_at]
    end

    def self.ransackable_associations(_auth_object = nil)
      ["series_themes"]
    end

    # Scopes for easier querying
    scope :main, -> { where(edition_id: nil) }
    scope :by_edition, ->(edition_id) { where(edition_id: edition_id) }

    # Class method to find by edition_id (replaces the YAML config lookup)
    def self.find_by_edition(edition_id)
      if edition_id.nil? || edition_id == "main"
        main.first
      else
        by_edition(edition_id).first
      end
    end

    # Returns all configs as a hash with edition_id as key (for compatibility)
    def self.all_as_hash
      all.index_by { |config| config.edition_id || :main }
    end

    # Returns all edition names/keys
    def self.config_names
      all.pluck(:edition_id).compact + [:main]
    end

    def locations
      return Web::Location.all if allow_all_locations

      # Only use valid location identifiers
      valid_identifiers = selectable_locations & Web::Location.pluck(:internal_identifier)
      Web::Location.by_internal_identifier(valid_identifiers)
    end

    # Helper method to get the default location object
    def default_location_object
      return nil unless default_location.present?

      Web::Location.find_by(internal_identifier: default_location)
    end

    # Clean up invalid location identifiers before saving
    before_save :clean_selectable_locations

    private

    def clean_selectable_locations
      return unless selectable_locations.present?

      valid_identifiers = Web::Location.pluck(:internal_identifier)
      self.selectable_locations = selectable_locations & valid_identifiers
    end
  end
end
