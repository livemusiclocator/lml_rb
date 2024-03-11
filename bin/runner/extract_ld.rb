# frozen_string_literal: true

require "open-uri"

file = ARGV.shift
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
File.open(file, "w") do |file|
  file.puts JSON.pretty_generate(docs)
end
