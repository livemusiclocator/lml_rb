require "rails_helper"

describe Lml::Upload do
  describe "process!" do
    context "where no data already existed" do
      before do
        @venue = Lml::Venue.create!(
          name: "THE VENUE NAME",
          time_zone: "Australia/Melbourne",
        )
      end

      it "populates status with failed when venue is missing" do
        upload = Lml::Upload.create!(
          time_zone: "Australia/Melbourne",
          format: "clipper",
          content: <<~CONTENT,
            url: the url
          CONTENT
        )
        upload.process!
        upload.reload

        expect(upload.status).to eq("Failed")
        expect(upload.error_description).to eq("A venue is required")
      end

      it "populates status with failed when name is missing" do
        upload = Lml::Upload.create!(
          time_zone: "Australia/Melbourne",
          venue: @venue,
          format: "clipper",
          content: <<~CONTENT,
            url: the url
            venue: the venue
          CONTENT
        )
        upload.process!
        upload.reload

        expect(upload.status).to eq("Failed")
        expect(upload.error_description).to eq("1: A date and gig name are required")
      end

      it "populates status with failed when date is missing" do
        upload = Lml::Upload.create!(
          time_zone: "Australia/Melbourne",
          venue: @venue,
          format: "clipper",
          content: <<~CONTENT,
            url: the url
            venue: the venue
            name: the gig name
          CONTENT
        )
        upload.process!
        upload.reload

        expect(upload.source).to eq("the url")
        expect(upload.status).to eq("Failed")
        expect(upload.error_description).to eq("1: A date and gig name are required")
      end
    end

    context "where data already existed" do
      before do
        @venue = Lml::Venue.create!(
          name: "THE VENUE NAME",
          time_zone: "Australia/Melbourne",
        )
        band3 = Lml::Act.create!(name: "BAND 3")
        gig = Lml::Gig.create!(
          name: "THE GIG NAME",
          venue: @venue,
          date: "2024-03-01",
          headline_act: band3,
        )
        Lml::Set.create!(gig: gig, act: band3)
        band2 = Lml::Act.create!(name: "BAND 2")
        Lml::Set.create!(gig: gig, act: band2)
      end

      it "leaves gig with existing names that match on case" do
        upload = Lml::Upload.create!(
          time_zone: "Australia/Melbourne",
          format: "clipper",
          source: "a website",
          venue: @venue,
          content: <<~CONTENT,
            name: the gig name
            date: 2024-03-01
          CONTENT
        )
        upload.process!
        upload.reload

        expect(upload.status).to eq("Succeeded")
        gig = Lml::Gig.find_by!(name: "THE GIG NAME")
        venue = Lml::Venue.find_by!(name: "THE VENUE NAME")
        expect(gig.venue).to eq(venue)
      end

      it "leaves existing gig and act names, replaces headline act and sets" do
        upload = Lml::Upload.create!(
          time_zone: "Australia/Melbourne",
          format: "clipper",
          source: "a website",
          venue: @venue,
          content: <<~CONTENT,
            name: the gig name
            date: 2024-03-01
            acts: band 1 | band 2
          CONTENT
        )
        upload.process!
        upload.reload

        expect(upload.status).to eq("Succeeded")
        gig = Lml::Gig.find_by!(name: "THE GIG NAME")
        act1 = Lml::Act.find_by!(name: "band 1")
        act2 = Lml::Act.find_by!(name: "BAND 2")
        expect(gig.headline_act).to eq(act1)
        expect(gig.sets.count).to eq(2)
        expect(Lml::Set.where(gig: gig, act: act1).count).to eq(1)
        expect(Lml::Set.where(gig: gig, act: act2).count).to eq(1)
      end
    end
  end
end
