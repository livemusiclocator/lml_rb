# frozen_string_literal: true

require "open-uri"

time_zone = ARGV.shift
url = ARGV.shift

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
    time_zone: time_zone,
    content: content,
  )
else
  upload = Lml::Upload.create!(
    time_zone: time_zone,
    source: url,
    format: "schema_org_events",
    content: content,
  )
end

upload.process!
