# frozen_string_literal: true

require "rails_helper"

describe "backstage proposals" do
  before do
    host! "www.livemusiclocator.com.au"

    @venue = create(:lml_venue, name: "The Tote")
    @gig = create(:lml_gig, venue: @venue, name: "Old name")
    @new_gig_params = {
      proposal: {
        proposed_type: "Lml::Gig",
        proposed_attributes: { name: "Brand new gig", date: "2026-11-14", venue_id: @venue.id },
      },
    }
    @amendment_params = {
      target_type: "Lml::Gig",
      target_id: @gig.id,
      proposal: { proposed_attributes: { name: "New name" } },
    }
  end

  describe "from an admin" do
    before { sign_in create(:lml_user, :admin) }

    it "applies a change to a gig straight away, with no proposal" do
      expect { post "/backstage/proposals", params: @amendment_params }.not_to change(Lml::Proposal, :count)

      expect(@gig.reload.name).to eq("New name")
      expect(flash[:notice]).to eq("Changes applied directly — you're an admin.")
    end

    it "creates a new gig straight away, with no proposal" do
      expect { post "/backstage/proposals", params: @new_gig_params }.not_to change(Lml::Proposal, :count)

      expect(@venue.gigs.find_by(name: "Brand new gig")).to be_present
      expect(response).to redirect_to("/backstage")
    end

    it "says so when the new gig's venue does not exist" do
      @new_gig_params[:proposal][:proposed_attributes][:venue_id] = SecureRandom.uuid

      expect { post "/backstage/proposals", params: @new_gig_params }.not_to change(Lml::Gig, :count)

      expect(flash[:alert]).to start_with("Could not create the gig")
    end
  end

  describe "from a plain backstage user" do
    before { sign_in create(:lml_user) }

    it "raises a proposal for a change to a gig and leaves the gig alone" do
      expect { post "/backstage/proposals", params: @amendment_params }.to change(Lml::Proposal.pending, :count).by(1)

      expect(@gig.reload.name).to eq("Old name")
    end

    it "raises a proposal for a new gig rather than creating it" do
      expect { post "/backstage/proposals", params: @new_gig_params }.to change(Lml::Proposal.pending, :count).by(1)

      expect(@venue.gigs.find_by(name: "Brand new gig")).to be_nil
    end
  end
end
