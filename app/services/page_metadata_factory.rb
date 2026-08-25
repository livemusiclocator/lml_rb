# frozen_string_literal: true

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
    # Place demands an address, and a venue we have not resolved yet has none.
    # Nil rather than an exception: to_json_ld renders nothing for nil, so the
    # page loses its json-ld instead of falling over. Reached through a gig this
    # was survivable - to_json_ld rescues in production - but the venue page
    # calls to_meta_tags too, and that path has no rescue.
    def generate_schema_dot_org
      return nil if @object.address.blank?

      SchemaDotOrg::Place.new(name: @object.name, address: @object.address)
    end

    # Never defined until the venue page needed one: until now a venue was only
    # ever generated nested inside a gig's Event, which asks for the schema and
    # not the tags, so this inherited BaseGenerator's raise.
    def generate_meta_tags
      { title: @object.name }
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

  class ActGenerator < BaseGenerator
    # The links we keep for an act are exactly what sameAs is for: other pages
    # that identify the same artist. website first, then alphabetical, matching
    # the order the json api renders them in.
    SAME_AS = %i[
      website bandcamp_url facebook_url instagram_url linktree_url
      musicbrainz_url rym_url spotify_url wikipedia_url youtube_url
    ].freeze

    def generate_schema_dot_org
      SchemaDotOrg::MusicGroup.new(
        name: @object.name,
        genre: @object.genres.presence,
        sameAs: SAME_AS.filter_map { |link| @object.public_send(link) }.presence,
      )
    end

    def generate_meta_tags
      { title: @object.name }
    end
  end

  # TODO: avoid using type names here as they play havoc with testing
  GENERATORS = {
    "Lml::Act" => ActGenerator,
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
