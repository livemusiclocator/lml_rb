# frozen_string_literal: true

module Lml
  # One place as the Places API returned it, and what it settles about a venue.
  #
  # Both the sheet import and the backfill go through this, so there is one answer to "what does
  # Google tell us about this venue" rather than two that can drift apart.
  #
  # See doc/google_sheets_venue_import.md.
  class Place # rubocop:disable Metrics/ClassLength
    # The resolved components that define address identity, and so what an existing venue is looked
    # up by. Which of these Google returns varies by country: locality is absent in GB (postal_town
    # is its equivalent) and subpremise is what distinguishes one tenancy from another.
    #
    # Matching is intersection based - the components are sliced down to these keys and the blanks
    # dropped - so a place that does not supply a key is simply not matched on it. Everything else
    # Google returns is excluded on purpose: lat/lng drift as coordinates are refined, the *_long
    # variants restate a key we already match on, administrative_area_level_2 has disagreeing short
    # and long forms, and `name` is frequently the business rather than the address.
    MATCH_KEYS = %w[
      subpremise
      street_number
      route
      locality
      postal_town
      administrative_area_level_1
      postal_code
      country
    ].freeze

    # Places has its own vocabulary for this; only the first means "still trading".
    OPERATIONAL = "OPERATIONAL"
    CLOSED_PERMANENTLY = "CLOSED_PERMANENTLY"

    # Rewritten every time, because it is the one thing here that genuinely changes: a venue that
    # has closed since it was last resolved is exactly what we want to hear about.
    VOLATILE = %i[google_business_status].freeze

    # Which place a venue *is*. Written once and then left alone - re-resolving a venue could point
    # it at a different place entirely (a name match on two venues sharing a name would be enough),
    # and silently moving an established venue's address is far worse than holding a slightly stale
    # one. The backfill refuses to re-resolve for the same reason.
    IDENTITY = %i[address_components google_place_id].freeze

    # Taken only where the venue has nothing there already. A blank column is a gap to fill; a
    # filled one is somebody's research, and Google is not a good enough reason to overwrite it.
    #
    # location_url is the map link the site shows, and the most tedious column to fill by hand,
    # so it takes googleMapsUri - the place's own listing - wherever nobody has chosen a link.
    FILL_INS = %i[time_zone address postcode latitude longitude location_url].freeze

    # Parameters that only say how somebody arrived at a link: Google's own g_mp on its maps links,
    # and the usual campaign and click ids. Anything else in a query string is left alone, since
    # some sites need theirs to find the page at all.
    TRACKING = /\A(utm_\w+|g_mp|gclid|fbclid|msclkid)\z/

    def initialize(payload)
      @payload = payload
    end

    def id
      @payload["id"]
    end

    def name
      @payload.dig("displayName", "text")
    end

    def formatted_address
      @payload["formattedAddress"]
    end

    # The address a venue shows: street and suburb, without the state, postcode and country that
    # formattedAddress tacks on - the postcode has its own column, and every venue is in Australia.
    def address
      @payload["shortFormattedAddress"].presence || formatted_address
    end

    def business_status
      @payload["businessStatus"]
    end

    # The link to the place's own listing on Google Maps, without the g_mp parameter Google adds
    # after the cid to say which API call produced it - it means nothing to a visitor.
    def maps_url
      without_tracking(@payload["googleMapsUri"])
    end

    # Business listings often carry campaign tags - the Tivoli's is ?utm_source=google&... - which
    # mean nothing on a venue page.
    def website
      without_tracking(@payload["websiteUri"])
    end

    def closed_permanently?
      business_status == CLOSED_PERMANENTLY
    end

    # Google answers with an IANA identifier, which is nearly always already one of ours - every
    # modern Australian zone is in CANONICAL_TIMEZONES. Timezone.canonical maps the deprecated names
    # onto ours and gives nil for anywhere we have no zone for, since a venue whose time_zone is not
    # one of ours fails validation and no answer beats a broken venue.
    def time_zone
      Lml::Timezone.canonical(@payload.dig("timeZone", "id"))
    end

    def components
      base = {
        "latitude" => location["latitude"],
        "longitude" => location["longitude"],
        "name" => name,
      }.compact

      address_components.each_with_object(base) { |component, result| add_component(result, component) }
    end

    def identity
      components.slice(*MATCH_KEYS).compact
    end

    # What to write onto this venue: whatever it has no value for yet, plus the volatile fields
    # regardless. Works for a Venue.new too, where nothing is filled in and so everything applies.
    #
    # Identity is all or nothing, gated on the components alone - a venue with components but no
    # place id was resolved by something else, and giving it this place's id would claim its address
    # came from here when it did not.
    #
    # The whole payload goes into google_place whenever this is the venue's place, so a fresh answer
    # replaces a stale one - but never onto a venue resolved to some other place, where it would
    # describe somewhere the rest of the venue is not.
    def attributes_for(venue)
      fill_ins.reject { |attribute, _| venue[attribute].present? }.merge(settled_for(venue))
    end

    # attributes_for without the fill-ins, for a venue form that has already shown them to a person
    # who kept or rejected each one.
    def settled_for(venue)
      settled = venue.address_components.blank? ? identity_attributes : {}
      if settled.fetch(:google_place_id, venue.google_place_id) == id
        settled = settled.merge(google_place: @payload, google_place_fetched_at: Time.current)
      end

      settled.merge(volatile)
    end

    # What a new venue's form starts from when this place is picked. Unlike attributes_for, nothing
    # here is written - it is all somebody's to check and change before they save.
    def form_attributes # rubocop:disable Metrics/MethodLength -- one line per form field
      {
        name: name,
        address: address,
        postcode: components["postal_code"],
        lga: council,
        lat_lng: location.values_at("latitude", "longitude").compact.join(", ").presence,
        time_zone: time_zone,
        website: website,
        phone: @payload["nationalPhoneNumber"],
        location_url: maps_url,
      }.compact
    end

    private

    def without_tracking(url)
      return url if url.blank?

      uri = URI.parse(url)
      params = URI.decode_www_form(uri.query.to_s).reject { |key, _| key.match?(TRACKING) }
      uri.query = params.empty? ? nil : URI.encode_www_form(params)
      uri.to_s
    rescue URI::InvalidURIError, ArgumentError
      url
    end

    # The local government area, which Google gives in its long form as the council's name.
    def council
      components["administrative_area_level_2_long"] || components["administrative_area_level_2"]
    end

    def location
      @payload["location"] || {}
    end

    def address_components
      @payload["addressComponents"] || []
    end

    def identity_attributes
      { address_components: components, google_place_id: id }
    end

    def volatile
      { google_business_status: business_status }
    end

    def fill_ins
      {
        time_zone: time_zone,
        address: address,
        postcode: components["postal_code"],
        latitude: components["latitude"],
        longitude: components["longitude"],
        location_url: maps_url,
      }.compact
    end

    # The long form is only kept where it differs from the short one, so that the components of a
    # place stay readable rather than restating VIC as Victoria for every key.
    def add_component(result, component)
      type = (component["types"] || []).first.presence || "unknown"

      result[type] = component["shortText"]
      result["#{type}_long"] = component["longText"] if component["shortText"] != component["longText"]
    end
  end
end
