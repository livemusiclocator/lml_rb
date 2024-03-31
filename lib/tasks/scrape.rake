# frozen_string_literal: true

require "open-uri"

namespace :scrape do
  desc "rescrape all existing schema_org_events uploads"
  task ld_json_all: :environment do
    Lml::Upload.where(format: "schema_org_events").each do |upload|
      next unless upload.source.start_with?("https://")

      puts "Rescraping #{upload.source}"
      upload.rescrape!
    end
  end

  desc "import a url containing application/ld+json content - requires either a VENUE_ID or TZ and URL"
  task ld_json: :environment do
    url = ENV.fetch("URL")

    venue_id = ENV.fetch("VENUE_ID", nil)
    if venue_id
      venue = Lml::Venue.find(venue_id) if venue_id
      time_zone = venue.time_zone
    else
      time_zone = ENV.fetch("TZ")
    end

    upload = Lml::Upload.find_by(
      source: url,
      format: "schema_org_events",
    )

    if upload
      upload.update!(
        time_zone: time_zone,
        venue: venue,
      )
    else
      upload = Lml::Upload.create!(
        content: "-",
        format: "schema_org_events",
        source: url,
        time_zone: time_zone,
        venue: venue,
      )
    end

    upload.rescrape!
  end
end
