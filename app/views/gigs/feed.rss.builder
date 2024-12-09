xml.instruct! :xml, version: "1.0"
xml.rss version: "2.0" do
  xml.channel do
    xml.title "Live Music Locator - gig feed"
    xml.description "Discover all live music events in the City of Yarra."
    xml.link "https://lml.live"
    xml.language "en"

    @gigs.each do |gig|
      xml.item do
        xml.title gig.display_name
        xml.description gig.rss_description
        xml.author "LML"
        xml.pubDate gig.updated_at.rfc822
        xml.link gig.lml_url
        xml.guid gig.lml_url
      end
    end
  end
end
