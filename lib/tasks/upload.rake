require "open-uri"

desc "import a url containing application/ld+json content - requires either a VENUE_ID or TZ and URL"
task import_ld_json: :environment do
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
