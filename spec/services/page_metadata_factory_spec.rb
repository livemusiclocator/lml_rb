# frozen_string_literal: true

require "rails_helper"

RSpec.describe "PageMetadataFactory" do
  context "GigSearch" do
    let(:gig_search) { build(:web_gig_search) }
    describe(:generate_schema_dot_org_for) do
      subject do
        PageMetadataFactory.generate_schema_dot_org_for(gig_search)
      end
      it "populates breadcrumbs" do
        is_expected.to be_a SchemaDotOrg::SearchResultsPage
      end
      it "populates name" do
        is_expected.to have_attributes(name: gig_search.title)
      end
      it "populates breadcrumb" do
        is_expected.to have_attributes(breadcrumb: gig_search.title)
      end
    end
    describe :to_meta_tags do
      subject do
        PageMetadataFactory.to_meta_tags(gig_search)
      end
      it "Populates the title attribute from the gig search generated title" do
        is_expected.to include(title: gig_search.title)
      end
    end
  end
  context "Gig" do
    let(:gig) { build(:lml_gig) }
    describe(:generate_schema_dot_org_for) do
      subject do
        PageMetadataFactory.generate_schema_dot_org_for(gig)
      end
      it "creates an Event schema object" do
        is_expected.to be_a SchemaDotOrg::Event
      end
      it "sets basic gig fields - name and date" do
        is_expected.to have_attributes(name: gig.name)
        is_expected.to have_attributes(startDate: gig.date)
      end
      it "populates the venue into location" do
        is_expected.to have_attributes(location: have_attributes(name: gig.venue.name, address: gig.venue.address))
        location = subject.location

        expect(location).to be_a SchemaDotOrg::Place
      end
    end
    describe "to_json_ld" do
      subject do
        PageMetadataFactory.to_json_ld(build(:lml_gig))
      end
      it "creates a script tag for embedding in an html page" do
        # worth testing rest of generation?
        is_expected.to include('<script type="application/ld+json">')
      end
      context "invalid source data" do
        subject do
          PageMetadataFactory.to_json_ld(build(:lml_gig, venue: build(:lml_venue, address: nil)))
        end
        it "handles valid data by returning nil" do
          is_expected.to be_nil
        end
      end
    end
    describe "to_meta_tags" do
      subject do
        PageMetadataFactory.to_meta_tags(build(:lml_gig))
      end
      it "Populates the title attribute from the gig name" do
        is_expected.to include(title: gig.name)
      end
    end
  end
end
