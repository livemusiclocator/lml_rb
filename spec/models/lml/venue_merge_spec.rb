# frozen_string_literal: true

require "rails_helper"

describe Lml::VenueMerge do
  before do
    @survivor = Lml::Venue.create!(name: "The Tote", location: "melbourne", time_zone: "Australia/Melbourne")
    @duplicate = Lml::Venue.create!(name: "Tote Hotel", location: "melbourne", time_zone: "Australia/Melbourne")
  end

  def merge
    Lml::VenueMerge.new(survivor: @survivor, duplicate: @duplicate).call
  end

  it "refuses to merge a venue into itself" do
    expect { Lml::VenueMerge.new(survivor: @survivor, duplicate: @survivor).call }
      .to raise_error(Lml::VenueMerge::Error, /into itself/)
  end

  describe "the duplicate's records" do
    before do
      @gig = Lml::Gig.create!(name: "A gig", venue: @duplicate, date: Date.current)
      Lml::Set.create!(gig: @gig, act: Lml::Act.create!(name: "A band"))
      @upload = Lml::Upload.create!(venue: @duplicate, content: "something")
      # confirmed_at, or creating the user sends a confirmation email and Devise's mailer has no
      # host to build its link from in a model spec.
      @manager = Lml::User.create!(
        email: "manager@example.com", password: "supersecret123", confirmed_at: Time.current,
      )
      Lml::VenueManager.create!(user: @manager, venue: @duplicate)
    end

    it "moves the gigs across, sets and all" do
      result = merge

      expect(result.gigs).to eq(1)
      expect(@gig.reload.venue).to eq(@survivor)
      expect(@gig.sets.count).to eq(1)
    end

    it "moves the uploads across rather than orphaning the gigs that came from them" do
      expect(merge.uploads).to eq(1)
      expect(@upload.reload.venue).to eq(@survivor)
    end

    # Polymorphic, so nothing in the database was going to stop these dangling.
    it "repoints an amendment proposal at the survivor" do
      user = Lml::User.create!(
        email: "proposer@example.com", password: "supersecret123", confirmed_at: Time.current,
      )
      proposal = Lml::Proposal.create!(user: user, target: @duplicate, proposed_attributes: { "capacity" => 10 })

      expect(merge.proposals).to eq(1)
      expect(proposal.reload.target).to eq(@survivor)
    end

    it "moves the managers across" do
      expect(merge.managers).to eq(1)
      expect(@survivor.reload.managers).to eq([@manager])
    end

    # venue_managers is unique on [user_id, venue_id], so this row cannot be moved onto a venue the
    # user already manages. The outcome that matters is that they still manage the survivor.
    it "drops a manager's duplicate row where they already manage the survivor" do
      Lml::VenueManager.create!(user: @manager, venue: @survivor)

      expect(merge.managers).to eq(0)
      expect(@survivor.reload.managers).to eq([@manager])
      expect(Lml::VenueManager.where(user: @manager).count).to eq(1)
    end

    it "destroys the duplicate once its gigs have gone" do
      merge

      expect(Lml::Venue.exists?(@duplicate.id)).to be(false)
    end

    it "leaves everything alone if the merge cannot be completed" do
      # A survivor that cannot be saved is the realistic way for this to fall over.
      @survivor.update_column(:time_zone, "Not/AZone")

      expect { merge }.to raise_error(ActiveRecord::RecordInvalid)
      expect(@gig.reload.venue).to eq(@duplicate)
      expect(Lml::Venue.exists?(@duplicate.id)).to be(true)
    end
  end

  describe "columns the survivor has no value for" do
    it "fills them in from the duplicate" do
      @duplicate.update!(capacity: 300, website: "https://thetote.example", phone: "9999")

      result = merge

      expect(@survivor.reload).to have_attributes(capacity: 300, website: "https://thetote.example", phone: "9999")
      expect(result.filled_in).to include("capacity", "website", "phone")
    end

    it "unions the tag lists" do
      @survivor.update!(tags: %w[rock])
      @duplicate.update!(tags: %w[punk rock])

      merge

      expect(@survivor.reload.tags).to eq(%w[rock punk])
    end

    it "inherits a researcher only when unassigned" do
      researcher = Lml::AdminUser.create!(
        email: "researcher@example.com", username: "res", password: "supersecret123",
        password_confirmation: "supersecret123", time_zone: "Australia/Melbourne",
      )
      @duplicate.update!(admin_user: researcher)

      merge

      expect(@survivor.reload.admin_user).to eq(researcher)
    end
  end

  describe "columns the duplicate knew differently" do
    it "keeps the survivor's value and records the duplicate's in its notes" do
      @survivor.update!(capacity: 250)
      @duplicate.update!(capacity: 300)

      result = merge

      expect(@survivor.reload.capacity).to eq(250)
      expect(@survivor.notes).to include('Capacity: 300')
      expect(result.discarded).to include("Capacity: 300")
    end

    it "records the duplicate's name, which is usually why it exists at all" do
      merge

      expect(@survivor.reload.notes).to include('Merged "Tote Hotel"')
      expect(@survivor.notes).to include('Name: "Tote Hotel"')
    end

    it "keeps the duplicate's own notes" do
      @survivor.update!(notes: "Load in round the back.")
      @duplicate.update!(notes: "Ask for Sam.")

      merge

      expect(@survivor.reload.notes).to include("Load in round the back.")
      expect(@survivor.notes).to include("Ask for Sam.")
    end

    it "says nothing about a column they agreed on" do
      @survivor.update!(capacity: 300)
      @duplicate.update!(capacity: 300)

      expect(merge.discarded).not_to include(/Capacity/)
    end
  end

  # Lml::Place writes a place id, its components and the business status together, and a place id
  # without the components it resolved would claim an address this venue never matched.
  describe "the google places columns" do
    before do
      @components = { "name" => "The Tote Hotel", "route" => "Johnston St", "street_number" => "71" }
    end

    it "moves all three when the survivor has none of them" do
      @duplicate.update!(
        google_place_id: "ChIJduplicate",
        address_components: @components,
        google_business_status: "OPERATIONAL",
      )

      merge

      expect(@survivor.reload).to have_attributes(
        google_place_id: "ChIJduplicate",
        address_components: @components,
        google_business_status: "OPERATIONAL",
      )
    end

    it "leaves all three alone and notes the id when the survivor resolved somewhere else" do
      @survivor.update!(google_place_id: "ChIJsurvivor", address_components: @components)
      @duplicate.update!(
        google_place_id: "ChIJduplicate",
        address_components: @components.merge("street_number" => "9"),
      )

      merge

      expect(@survivor.reload.google_place_id).to eq("ChIJsurvivor")
      expect(@survivor.notes).to include('Google place id: "ChIJduplicate"')
      # The blob itself has no business in a notes field.
      expect(@survivor.notes).not_to include("Johnston St")
    end
  end

  describe "the coordinate" do
    it "moves both halves together" do
      @duplicate.update!(latitude: -37.8, longitude: 145.0)

      merge

      expect(@survivor.reload.lat_lng).to eq("-37.8, 145.0")
    end

    it "is not half moved when the duplicate only has one half" do
      @duplicate.update!(latitude: -37.8)

      merge

      expect(@survivor.reload.latitude).to be_nil
    end
  end
end
