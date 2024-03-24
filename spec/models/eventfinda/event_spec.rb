# frozen_string_literal: true

require "rails_helper"
RSpec.describe Eventfinda::Event, type: :model do
  describe :to_schema_org_builder do
    subject { Eventfinda::Event.new({}) }
    let(:result) { JSON.parse(subject.to_schema_org_builder.target!) }

    it "creates a schema org object of type MusicEvent" do
      expect(result).to include("@context" => "https://schema.org", "@type" => "MusicEvent")
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
      expect(result).to include("startDate" => "2022-02-05T19:00:00+10:30", "endDate" => "2022-02-05T23:00:00+10:30")
    end

    it "outputs results from location and image data" do
      subject.location = double(:location, to_schema_org_builder: "A Place")
      subject.images = double(:images, to_schema_org_builder: "A Picture")

      expect(result).to include("location" => "A Place", "image" => "A Picture")
    end

    context "event is cancelled" do
      it "sets status to EventCancelled" do
        subject.is_cancelled = true
        expect(result["eventStatus"]).to end_with("EventCancelled")
      end
    end
  end
end
