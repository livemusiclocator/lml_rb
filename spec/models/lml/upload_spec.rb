require "rails_helper"

describe Lml::Upload do
  describe "process!" do
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

    context "where the gig did not already exist" do
      it "creates " do
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
        gig = Lml::Gig.find_by!(name: "the gig name")
        expect(gig.date).to eq(Date.iso8601("2024-03-01"))
        expect(gig.venue).to eq(@venue)
        expect(gig.status).to eq("confirmed")
        expect(gig.source).to eq("a website")
        expect(gig.upload).to eq(upload)
      end
    end

    context "where the gig already existed" do
      before do
        band3 = Lml::Act.create!(name: "BAND 3")
        gig = Lml::Gig.create!(
          name: "THE GIG NAME",
          venue: @venue,
          date: "2024-03-01",
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
        expect(gig.status).to eq("confirmed")
      end

      it "leaves existing gig and act names, replaces sets" do
        upload = Lml::Upload.create!(
          time_zone: "Australia/Melbourne",
          format: "clipper",
          source: "a website",
          venue: @venue,
          content: <<~CONTENT,
            name: the gig name
            date: 2024-03-01
            set: band 1 (Melbourne)
            set: band 2 (Glasgow/Scotland)
            set: band 4
          CONTENT
        )
        upload.process!
        upload.reload

        expect(upload.status).to eq("Succeeded")


        act1 = Lml::Act.find_by!(name: "band 1")
        expect(act1.location).to eq("Melbourne")
        expect(act1.country).to eq("Australia")
        act2 = Lml::Act.find_by!(name: "BAND 2")
        expect(act2.location).to eq("Glasgow")
        expect(act2.country).to eq("Scotland")
        act4 = Lml::Act.find_by!(name: "band 4")
        expect(act4.location).to eq(nil)
        expect(act4.country).to eq(nil)

        gig = Lml::Gig.find_by!(name: "THE GIG NAME")
        expect(gig.sets.count).to eq(3)
        expect(Lml::Set.where(gig: gig, act: act1).count).to eq(1)
        expect(Lml::Set.where(gig: gig, act: act2).count).to eq(1)
        expect(Lml::Set.where(gig: gig, act: act4).count).to eq(1)
      end
    end
  end
end
