# frozen_string_literal: true

module SchemaDotOrg
  class SearchResultsPage < SchemaDotOrg::SchemaType
    validated_attr :breadcrumb, type: String, allow_nil: true
    validated_attr :name, type: String, allow_nil: true
  end

  class Place < SchemaDotOrg::SchemaType
    validated_attr :address, type: String, presence: true
    validated_attr :name, type: String, presence: false
  end

  class Event < SchemaDotOrg::SchemaType
    validated_attr :name, type: String, allow_nil: false
    validated_attr :startDate, type: Date
    validated_attr :location, type: Place
  end
end

class PageMetadataFactory
  class BaseGenerator
    def initialize(object)
      @object = object
    end

    def generate_schema_dot_org
      raise NotImplementedError, "Subclasses must implement #generate_schema_dot_org"
    end

    def generate_meta_tags
      raise NotImplementedError, "Subclasses must implement #generate_meta_tags"
    end

    private

    attr_reader :object
  end

  class GigSearchGenerator < BaseGenerator
    def generate_schema_dot_org
      SchemaDotOrg::SearchResultsPage.new(name: @object.title, breadcrumb: @object.title)
    end

    def generate_meta_tags
      { title: @object.title }
    end
  end

  class VenueGenerator < BaseGenerator
    def generate_schema_dot_org
      SchemaDotOrg::Place.new(name: @object.name, address: @object.address)
    end
  end

  class GigGenerator < BaseGenerator
    def generate_schema_dot_org
      SchemaDotOrg::Event.new(name: @object.name,
                              startDate: @object.date,
                              location: PageMetadataFactory.generate_schema_dot_org_for(@object.venue),)
    end

    def generate_meta_tags
      { title: @object.name }
    end
  end
  GENERATORS = {
    "Lml::Gig" => GigGenerator,
    "Lml::Venue" => VenueGenerator,
    "Web::GigSearch" => GigSearchGenerator,
  }.freeze

  def self.generate_schema_dot_org_for(object)
    generator_class = GENERATORS[object.class.name]
    generator_class&.new(object)&.generate_schema_dot_org
  end

  def self.to_meta_tags(object)
    generator_class = GENERATORS[object.class.name]
    generator_class&.new(object)&.generate_meta_tags
  end

  def self.to_json_ld(object)
    if Rails.env.development?
      _to_json_ld(object)
    else
      begin
        _to_json_ld(object)
      rescue StandardError => e
        Rails.logger.error("Error during json+ld schema generation: #{e}")
        nil
      end
    end
  end

  def self._to_json_ld(object)
    result = generate_schema_dot_org_for(object)
    result&.to_s
  end
end
