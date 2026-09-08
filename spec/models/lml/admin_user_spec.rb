# frozen_string_literal: true

require "rails_helper"

describe Lml::AdminUser do
  before do
    @admin_user = described_class.create!(
      email: "admin_user_spec@example.com",
      username: "auspec",
      password: "supersecret123",
      password_confirmation: "supersecret123",
      time_zone: "Australia/Melbourne",
    )
  end

  describe "being destroyed" do
    it "unassigns the venues it was researching rather than deleting them" do
      venue = Lml::Venue.create!(
        name: "The Tote", location: "melbourne", time_zone: "Australia/Melbourne", admin_user: @admin_user,
      )

      @admin_user.destroy!

      expect(venue.reload.admin_user).to be_nil
    end

    # proposals.reviewed_by_id has a foreign key, and until this association existed there was
    # nothing on this side to satisfy it, so the delete came back as a 500.
    it "keeps the proposals it reviewed, minus the reviewer" do
      user = Lml::User.create!(
        email: "proposer@example.com", password: "supersecret123", confirmed_at: Time.current,
      )
      proposal = Lml::Proposal.create!(
        user: user,
        proposed_type: "Lml::Gig",
        proposed_attributes: { "name" => "A gig" },
        reviewed_by: @admin_user,
        reviewer_note: "Looks right to me.",
      )

      expect { @admin_user.destroy! }.not_to raise_error

      expect(proposal.reload.reviewed_by).to be_nil
      # The substance of the review outlives the account that made it.
      expect(proposal.reviewer_note).to eq("Looks right to me.")
    end
  end
end
