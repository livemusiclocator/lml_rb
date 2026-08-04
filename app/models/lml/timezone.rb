module Lml
  module Timezone
    CANONICAL_TIMEZONES = %w[
      Australia/Adelaide
      Australia/Brisbane
      Australia/Broken_Hill
      Australia/Canberra
      Australia/Darwin
      Australia/Eucla
      Australia/Hobart
      Australia/Lindeman
      Australia/Lord_Howe
      Australia/Melbourne
      Australia/Perth
      Australia/Sydney
    ].freeze

    TIMEZONES = {
      "Adelaide" => "Australia/Adelaide",
      "Brisbane" => "Australia/Brisbane",
      "Canberra" => "Australia/Canberra",
      "Darwin" => "Australia/Darwin",
      "Hobart" => "Australia/Hobart",
      "Melbourne" => "Australia/Melbourne",
      "Perth" => "Australia/Perth",
      "Sydney" => "Australia/Sydney",

      # The rest are IANA's deprecated Australian names, kept as backward compatibility links to the
      # modern ones. Nothing we talk to should use them - Google Places answers with the modern name
      # - but they are still valid identifiers, so converting them costs nothing and means an
      # unexpected one lands on the right zone instead of being thrown away.
      "Australia/ACT" => "Australia/Canberra",
      "Australia/Currie" => "Australia/Hobart",
      "Australia/LHI" => "Australia/Lord_Howe",
      "Australia/NSW" => "Australia/Sydney",
      "Australia/North" => "Australia/Darwin",
      "Australia/Queensland" => "Australia/Brisbane",
      "Australia/South" => "Australia/Adelaide",
      "Australia/Tasmania" => "Australia/Hobart",
      "Australia/Victoria" => "Australia/Melbourne",
      "Australia/West" => "Australia/Perth",
      "Australia/Yancowinna" => "Australia/Broken_Hill",
    }.freeze

    def self.convert(identifier)
      TIMEZONES[identifier] || identifier
    end

    # The canonical name for an identifier, or nil where we have no zone of our own for it. A venue
    # whose time_zone is outside CANONICAL_TIMEZONES fails validation, so callers taking a zone from
    # somewhere else want nil rather than something unusable.
    def self.canonical(identifier)
      converted = convert(identifier)

      converted if CANONICAL_TIMEZONES.include?(converted)
    end
  end
end
