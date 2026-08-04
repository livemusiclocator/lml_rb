# frozen_string_literal: true

require "faraday"
require "json"

module Lml
  # Thin wrapper over the Places API (New). Note that this is a different product to the legacy
  # "Places API" - the project needs "Places API (New)" enabled or every call 403s.
  #
  # See doc/google_sheets_venue_import.md for the credential setup.
  class GooglePlacesApiClient
    API_KEY_VAR = "GOOGLE_PLACES_SERVER_KEY"

    FIND_URL = "https://places.googleapis.com/v1/places:searchText"
    DETAILS_URL = "https://places.googleapis.com/v1/places/%<place_id>s"

    # Places bills per request by the most expensive tier any requested field belongs to, and only
    # returns what is asked for. Every field here is in the "Pro" tier, which this call was already
    # in for addressComponents alone, so all of them together cost exactly what the original four
    # did. `websiteUri` and `nationalPhoneNumber` would be useful too but are Enterprise tier, which
    # is a deliberate price change rather than a free one.
    #
    # Only fields something actually reads are listed - an unused field is free but still noise.
    # See doc/google_sheets_venue_import.md.
    FIND_FIELDS = %w[
      places.id
      places.displayName
      places.formattedAddress
      places.addressComponents
      places.location
      places.googleMapsUri
      places.businessStatus
      places.timeZone
    ].join(",").freeze

    class Error < StandardError; end

    def initialize(api_key: ENV.fetch(API_KEY_VAR, nil))
      @api_key = api_key
      @client = Faraday.new
    end

    # region_code is a CLDR country code. Google treats it as a bias rather than a hard filter - it
    # reranks and formats results for that region but does not guarantee excluding results outside
    # it. Use locationRestriction if a genuine restriction is ever needed.
    def find(query, region_code: nil, field_mask: FIND_FIELDS)
      body = { textQuery: query }
      body[:regionCode] = region_code if region_code.present?

      parsed(@client.post(FIND_URL, body.to_json, headers(field_mask)))
    end

    def details(place_id, field_mask: "*")
      url = format(DETAILS_URL, place_id: place_id)

      parsed(@client.get(url, {}, headers(field_mask)))
    end

    private

    def headers(field_mask)
      {
        "X-Goog-Api-Key" => @api_key,
        "X-Goog-FieldMask" => field_mask,
        "Content-Type" => "application/json",
      }
    end

    def parsed(response)
      raise Error, "places api returned #{response.status}: #{response.body}" unless response.success?

      JSON.parse(response.body)
    end
  end
end
