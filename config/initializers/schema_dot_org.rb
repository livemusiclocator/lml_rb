# frozen_string_literal: true

# Extensions to the schema_dot_org gem's vocabulary.
#
# This has to be an initializer rather than anything autoloaded: Place already
# exists in the gem, with address only, and we reopen it to add name. Zeitwerk
# will not autoload a constant that is already defined, so an app/ file here
# would silently never load and Place would quietly lose its name attribute.
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
