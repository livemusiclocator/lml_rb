require "rails_helper"

describe Lml::Processors::SchemaOrgEvents do
  describe "process!" do
    context "when venue is not specified" do
      it "creates gigs and venue" do
        upload = double(
          "upload",
          content: File.read("spec/files/tivoli_schema_org_events.json"),
          venue: nil,
        )

        Lml::Processors::SchemaOrgEvents.new(upload).process!

        expect(Lml::Venue.count).to eq(1)
        expect(Lml::Venue.first.name).to eq("The Tivoli")
        expect(Lml::Gig.count).to eq(16)
      end
    end

    context "when venue is specified" do
      it "creates gigs" do
        venue = Lml::Venue.create!(name: "The Venue")
        upload = double(
          "upload",
          content: File.read("spec/files/tivoli_schema_org_events.json"),
          venue: venue,
        )

        Lml::Processors::SchemaOrgEvents.new(upload).process!

        expect(Lml::Venue.count).to eq(1)
        expect(Lml::Venue.first.name).to eq("The Venue")
        expect(Lml::Gig.count).to eq(16)
      end
    end
  end
end
