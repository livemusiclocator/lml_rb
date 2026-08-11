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

    # Worth retrying: a 503 means Google's side is briefly at capacity rather than anything being
    # wrong with the request, and one in a few hundred is normal. A 429 is a rate limit, which is
    # also just a matter of waiting - and where it is a daily quota instead, the attempt cap stops us
    # sitting on it.
    #
    # Deliberately not everything Google's best practices page suggests retrying: it says to retry
    # 4XX as well, but a 403 for an API that is not enabled and a 400 for a malformed request are
    # faults no amount of waiting fixes, and retrying them just makes a misconfiguration take four
    # times as long to report.
    RETRY_STATUSES = [429, 500, 502, 503, 504].freeze

    NETWORK_ERRORS = [Faraday::ConnectionFailed, Faraday::TimeoutError].freeze

    # Google's own guidance: start at 100ms and double, giving up after a few seconds.
    MAX_ATTEMPTS = 4
    INITIAL_DELAY = 0.1
    MAX_DELAY = 5.0

    class Error < StandardError; end

    def initialize(api_key: ENV.fetch(API_KEY_VAR, nil), initial_delay: INITIAL_DELAY)
      @api_key = api_key
      @initial_delay = initial_delay
      @client = Faraday.new
    end

    # region_code is a CLDR country code. Google treats it as a bias rather than a hard filter - it
    # reranks and formats results for that region but does not guarantee excluding results outside
    # it. Use locationRestriction if a genuine restriction is ever needed.
    def find(query, region_code: nil, field_mask: FIND_FIELDS)
      body = { textQuery: query }
      body[:regionCode] = region_code if region_code.present?

      with_retries { @client.post(FIND_URL, body.to_json, headers(field_mask)) }
    end

    def details(place_id, field_mask: "*")
      url = format(DETAILS_URL, place_id: place_id)

      with_retries { @client.get(url, {}, headers(field_mask)) }
    end

    private

    def headers(field_mask)
      {
        "X-Goog-Api-Key" => @api_key,
        "X-Goog-FieldMask" => field_mask,
        "Content-Type" => "application/json",
      }
    end

    # A run that walks hundreds of venues will meet the odd transient failure, and without this one
    # of them costs that venue its turn. Retrying here rather than in the callers means the sheet
    # import and the backfill both get it.
    def with_retries(&request)
      delay = @initial_delay

      (1..MAX_ATTEMPTS).each do |attempt|
        final = attempt == MAX_ATTEMPTS

        outcome = attempt_once(final, &request)

        return outcome.fetch(:parsed) if outcome.key?(:parsed)

        sleep(jittered(delay))
        delay = [delay * 2, MAX_DELAY].min
      end

      # Unreachable - the last attempt either answers or raises - but without it the method would
      # quietly return the range that `each` gives back.
      raise Error, "places api gave up after #{MAX_ATTEMPTS} attempts"
    end

    # Returns { parsed: ... } where there is an answer, and an empty hash where it is worth another
    # go. Raises where it is not, or where this was the last attempt.
    def attempt_once(final)
      response = yield

      return { parsed: JSON.parse(response.body) } if response.success?

      if final || RETRY_STATUSES.exclude?(response.status)
        raise Error, "places api returned #{response.status}: #{response.body}"
      end

      {}
    rescue *NETWORK_ERRORS => e
      raise Error, "places api unreachable: #{e.message}" if final

      {}
    end

    # Google's example has no jitter, but a little keeps a batch from lining its retries up.
    def jittered(delay)
      delay * (1 + (rand * 0.25))
    end
  end
end
