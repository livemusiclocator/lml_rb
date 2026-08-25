# frozen_string_literal: true

require "rails_helper"

RSpec.describe "PageMetadataFactory" do
  context "with GigSearch page data" do
    let(:gig_search) { instance_double(Web::GigSearch, { title: "Gig search title" }) }

    describe "generate_schema_dot_org" do
      let :schema do
        PageMetadataFactory::GigSearchGenerator.new(gig_search).generate_schema_dot_org
      end

      it "creates correct schema.org type" do
        expect(schema).to be_a SchemaDotOrg::SearchResultsPage
      end

      it "populates name" do
        expect(schema).to have_attributes(name: gig_search.title)
      end

      it "populates breadcrumb" do
        expect(schema).to have_attributes(breadcrumb: gig_search.title)
      end
    end

    describe "to_meta_tags" do
      let :meta_tags do
        PageMetadataFactory::GigSearchGenerator.new(gig_search).generate_meta_tags
      end

      it "Populates the title attribute from the gig search generated title" do
        expect(meta_tags).to include(title: gig_search.title)
      end
    end
  end

  # Instance variables in a before block, per the repo convention - the let based
  # contexts around this one predate it.
  context "with act page data" do
    before do
      @act = build(:lml_act,
                   name: "Amyl and the Sniffers",
                   genres: ["punk", "garage rock"],
                   website: "https://amyl.example",
                   instagram: "amylandthesniffers",)
    end

    describe "generate_schema_dot_org_for" do
      it "creates a MusicGroup schema object" do
        schema = PageMetadataFactory.generate_schema_dot_org_for(@act)

        expect(schema).to be_a(SchemaDotOrg::MusicGroup)
          .and have_attributes(name: "Amyl and the Sniffers", genre: ["punk", "garage rock"])
      end

      # sameAs is the schema.org way of saying "these pages are the same artist",
      # which is exactly what the handles we keep resolve to.
      it "collects the act's other pages into sameAs" do
        schema = PageMetadataFactory.generate_schema_dot_org_for(@act)

        expect(schema.sameAs).to eq(["https://amyl.example",
                                     "https://www.instagram.com/amylandthesniffers",])
      end

      it "leaves genre and sameAs out rather than sending empty ones" do
        schema = PageMetadataFactory.generate_schema_dot_org_for(build(:lml_act, genres: []))

        expect(schema).to have_attributes(genre: nil, sameAs: nil)
      end
    end

    describe "to_json_ld" do
      it "creates a script tag for embedding in an html page" do
        expect(PageMetadataFactory.to_json_ld(@act))
          .to include('<script type="application/ld+json">', '"@type": "MusicGroup"')
      end
    end

    describe "to_meta_tags" do
      it "populates the title attribute from the act name" do
        expect(PageMetadataFactory.to_meta_tags(@act)).to include(title: "Amyl and the Sniffers")
      end
    end
  end

  context "with gig page data" do
    let(:gig) { build(:lml_gig) }

    describe "generate_schema_dot_org_for" do
      let :schema do
        PageMetadataFactory.generate_schema_dot_org_for(gig)
      end

      it "creates an Event schema object" do
        expect(schema).to be_a(SchemaDotOrg::Event)
          .and have_attributes(name: gig.name, startDate: gig.date)
      end

      it "populates the venue into location" do
        expect(schema.location).to be_a(SchemaDotOrg::Place)
          .and have_attributes(name: gig.venue.name, address: gig.venue.address)
      end
    end

    describe "to_json_ld" do
      it "creates a script tag for embedding in an html page" do
        script_tag = PageMetadataFactory.to_json_ld(build(:lml_gig))
        expect(script_tag).to include('<script type="application/ld+json">')
      end

      it "handles invalid data by returning nil" do
        script_tag = PageMetadataFactory.to_json_ld("not a thing")
        expect(script_tag).to be_nil
      end
    end

    describe "to_meta_tags" do
      let :meta_tags do
        PageMetadataFactory.to_meta_tags(build(:lml_gig))
      end

      it "Populates the title attribute from the gig name" do
        expect(meta_tags).to include(title: gig.name)
      end
    end
  end
end
