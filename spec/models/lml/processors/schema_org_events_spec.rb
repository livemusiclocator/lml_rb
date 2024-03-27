require "rails_helper"

describe Lml::Processors::SchemaOrgEvents do
  describe "process!" do
    context "when venue is not specified" do
      it "creates gigs and venue" do
        upload = Lml::Upload.create!(
          content: File.read("spec/files/tivoli_schema_org_events.json"),
          format: "schema_org_events",
          source: "original url",
          time_zone: "Melbourne",
        )

        upload.process!

        expect(Lml::Venue.count).to eq(1)
        expect(Lml::Venue.first.name).to eq("The Tivoli")
        expect(Lml::Gig.count).to eq(20)
      end
    end

    context "when venue is specified" do
      it "creates gigs" do
        venue = Lml::Venue.create!(name: "The Venue")
        upload = Lml::Upload.create!(
          content: File.read("spec/files/tivoli_schema_org_events.json"),
          format: "schema_org_events",
          source: "original url",
          time_zone: "Melbourne",
          venue: venue,
        )

        upload.process!

        expect(Lml::Venue.count).to eq(1)
        expect(Lml::Venue.first.name).to eq("The Venue")
        expect(Lml::Gig.count).to eq(20)
      end
    end
  end
end
