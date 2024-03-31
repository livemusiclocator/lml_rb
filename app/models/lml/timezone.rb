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

      "Australia/Queensland" => "Australia/Brisbane",
      "Australia/Tasmania" => "Australia/Hobart",
    }.freeze

    def self.convert(identifier)
      TIMEZONES[identifier] || identifier
    end
  end
end
