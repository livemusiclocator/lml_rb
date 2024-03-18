require 'rails_helper'
# todo: what is the trad way of doing this?
include Lml::Processors::Eventfinda
RSpec.describe Lml::Processors::Eventfinda::Event, type: :model do
  describe :to_schema_org_builder do
    subject { Event.new({images: [], location:{}})}
    let(:result) { JSON.parse(subject.to_schema_org_builder.target!) }

    it "creates a schema org object of type MusicEvent" do
      expect(result).to include("@context"=>"https://schema.org", "@type" => "MusicEvent")
    end

    it "populates basic fields related to the event" do
      subject.url = "https://eventfinda.com.au/thisevent"
      subject.name = "My cool event"
      subject.description = "Blah blah"
      expect(result).to include(subject.slice(:name, :url, :description))
      expect(result["eventStatus"]).to end_with("EventScheduled")
      expect(result["eventAttendanceMode"]).to end_with("OfflineEventAttendanceMode")
    end

    it "populates event start and finish times with timezones" do
      subject.datetime_start = "2022-02-05 19:00:00"
      subject.datetime_end = "2022-02-05 23:00:00"
      subject.timezone = "Australia/Adelaide"
      expect(result).to include("startDate"=>"2022-02-05T19:00:00+10:30", "endDate"=>"2022-02-05T23:00:00+10:30")
    end

    describe :location do

      it "createas a schema org object of type Place" do
        expect(result["location"]).to include("@type" => "Place")
      end

      it "populates basic information relating to the location" do
        subject.location.name = "The Moon"
        subject.location.summary = "Earth's Orbit"
        expect(result["location"]).to include("name"=>"The Moon", "address"=> "Earth's Orbit")
      end
      it "adds links back to original location using url-slug" do
        subject.location.url_slug = "the-moon"
        expect(result["location"]).to include("sameAs"=>"https://www.eventfinda.com.au/venue/the-moon")
      end
      it "adds a geo for the lat/long point data" do
        subject.location.point.lat = 51.4419
        subject.location.point.lng = 0.3708

        expect(result.dig("location", "geo")).to include("@type"=>"GeoCoordinates", "latitude" => 51.4419, "longitude" => 0.37080)

      end
    end
    context "at least one primary image is present" do

      #todo : do we want to pick one of the transformed images (different sizes)
      it "adds an image url" do
        subject.images = [Image.new(is_primary: true, original_url: "https://cdn/image.jpg" )]
        expect(result).to include("image"=> subject.images[0].original_url)
      end

    end

    context "event is cancelled" do
      it "sets status to EventCancelled" do
        subject.is_cancelled = true
        expect(result["eventStatus"]).to end_with("EventCancelled")
      end
    end



  end
end
