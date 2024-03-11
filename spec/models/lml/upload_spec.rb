require "rails_helper"

describe Lml::Upload do
  describe "process!" do
    context "where no data already existed" do
      it "creates a gig when only gig name is present" do
        upload = Lml::Upload.create!(
          format: "clipper",
          source: "a website",
          content: <<~CONTENT,
            gig name: the gig name
          CONTENT
        )
        upload.process!
        gig = Lml::Gig.find_by!(name: "the gig name")
        expect(gig.venue).to be_nil
        expect(gig.headline_act).to be_nil
      end

      it "creates a gig and venue" do
        upload = Lml::Upload.create!(
          format: "clipper",
          source: "a website",
          content: <<~CONTENT,
            gig name: the gig name
            venue name: the venue name
          CONTENT
        )
        upload.process!
        gig = Lml::Gig.find_by!(name: "the gig name")
        venue = Lml::Venue.find_by!(name: "the venue name")
        expect(gig.venue).to eq(venue)
      end

      it "creates a gig, an act and sets" do
        upload = Lml::Upload.create!(
          format: "clipper",
          source: "a website",
          content: <<~CONTENT,
            gig name: the gig name
            acts: band 1 | band 2
          CONTENT
        )
        upload.process!
        gig = Lml::Gig.find_by!(name: "the gig name")
        act1 = Lml::Act.find_by!(name: "band 1")
        act2 = Lml::Act.find_by!(name: "band 2")
        expect(gig.headline_act).to eq(act1)
        expect(gig.sets.count).to eq(2)
        expect(Lml::Set.where(gig: gig, act: act1).count).to eq(1)
        expect(Lml::Set.where(gig: gig, act: act2).count).to eq(1)
      end
    end

    context "where data already existed" do
      before do
        venue = Lml::Venue.create!(name: "THE VENUE NAME")
        band3 = Lml::Act.create!(name: "BAND 3")
        gig = Lml::Gig.create!(
          name: "THE GIG NAME",
          venue: venue,
          headline_act: band3,
        )
        Lml::Set.create!(gig: gig, act: band3)
        band2 = Lml::Act.create!(name: "BAND 2")
        Lml::Set.create!(gig: gig, act: band2)
      end

      it "leaves gig and venue with existing names that match on case" do
        upload = Lml::Upload.create!(
          format: "clipper",
          source: "a website",
          content: <<~CONTENT,
            gig name: the gig name
            venue name: the venue name
          CONTENT
        )
        upload.process!
        gig = Lml::Gig.find_by!(name: "THE GIG NAME")
        venue = Lml::Venue.find_by!(name: "THE VENUE NAME")
        expect(gig.venue).to eq(venue)
      end

      it "leaves existing gig and act names, replaces headline act and sets" do
        upload = Lml::Upload.create!(
          format: "clipper",
          source: "a website",
          content: <<~CONTENT,
            gig name: the gig name
            acts: band 1 | band 2
          CONTENT
        )
        upload.process!
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
