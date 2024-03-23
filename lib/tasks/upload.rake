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

  docs = []
  page = Nokogiri::HTML(URI.open(url))
  page.css('script[type="application/ld+json"]').each do |ld|
    html_content = ld.inner_html.strip
    doc = JSON.parse(html_content)
    if html_content[0] == "["
      docs += doc
    else
      docs << doc
    end
  end

  content = JSON.pretty_generate(docs)

  upload = Lml::Upload.find_by(
    source: url,
    format: "schema_org_events",
  )

  if upload
    upload.update!(
      content: content,
      time_zone: time_zone,
      venue: venue,
    )
  else
    upload = Lml::Upload.create!(
      content: content,
      format: "schema_org_events",
      source: url,
      time_zone: time_zone,
      venue: venue,
    )
  end

  upload.process!
end
