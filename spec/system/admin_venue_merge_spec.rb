# frozen_string_literal: true

require "rails_helper"

# Lml::VenueMerge has its own spec for the folding rules; this drives the sidebar that reaches it,
# because a picker whose element ids do not line up with attachSearchAutocomplete attaches to
# nothing and submits an empty venue_id, which no request spec would notice.
describe "merging a duplicate venue in admin", type: :system do
  before do
    @password = "supersecret123"
    @admin_user = Lml::AdminUser.create!(
      email: "venue_merge_spec@example.com",
      username: "merger",
      password: @password,
      password_confirmation: @password,
      time_zone: "Australia/Melbourne",
    )

    sign_in_as_admin

    @survivor = Lml::Venue.create!(name: "The Tote", location: "melbourne", time_zone: "Australia/Melbourne")
    @duplicate = Lml::Venue.create!(
      name: "Tote Hotel", location: "melbourne", time_zone: "Australia/Melbourne", capacity: 300,
    )
    @gig = Lml::Gig.create!(name: "A gig", venue: @duplicate, date: Date.current)
    Lml::Set.create!(gig: @gig, act: Lml::Act.create!(name: "A band"))
  end

  def sign_in_as_admin
    visit "/admin/login"
    fill_in "admin_user_email", with: @admin_user.email
    fill_in "admin_user_password", with: @password
    find("input[type=submit]").click

    raise "admin sign in failed" unless page.has_no_css?("#admin_user_password")
  end

  def pick_duplicate
    fill_in "venue_label", with: "Tote Hotel"
    within("#merge_venue_results") { find("div", text: "Tote Hotel (melbourne)").click }
  end

  it "suggests venues and records the chosen one's id" do
    visit "/admin/venues/#{@survivor.id}"
    pick_duplicate

    expect(find("#merge_venue_id", visible: :hidden).value).to eq(@duplicate.id)
  end

  it "moves the gigs across and deletes the duplicate" do
    visit "/admin/venues/#{@survivor.id}"
    pick_duplicate
    click_button "Merge into this venue"

    expect(page).to have_content('Merged "Tote Hotel" into The Tote.')
    expect(page).to have_content("Moved 1 gig.")
    expect(@gig.reload.venue).to eq(@survivor)
    expect(Lml::Venue.exists?(@duplicate.id)).to be(false)
  end

  it "reports the columns it filled in" do
    visit "/admin/venues/#{@survivor.id}"
    pick_duplicate
    click_button "Merge into this venue"

    expect(page).to have_content("Filled in capacity")
    expect(@survivor.reload.capacity).to eq(300)
  end

  it "records what the duplicate knew differently in the notes" do
    @survivor.update!(capacity: 250)

    visit "/admin/venues/#{@survivor.id}"
    pick_duplicate
    click_button "Merge into this venue"

    expect(page).to have_content("Recorded 2 differing values in the notes.")
    # The show page renders notes, so the record is visible where somebody will find it.
    expect(page).to have_content('Merged "Tote Hotel"')
    expect(page).to have_content("Capacity: 300")
    expect(@survivor.reload.capacity).to eq(250)
  end

  it "says so rather than 500ing when nothing was picked" do
    visit "/admin/venues/#{@survivor.id}"
    click_button "Merge into this venue"

    expect(page).to have_content("Pick a venue to merge in first.")
    expect(Lml::Venue.exists?(@duplicate.id)).to be(true)
  end

  it "refuses to merge a venue into itself" do
    visit "/admin/venues/#{@survivor.id}"
    fill_in "venue_label", with: "The Tote"
    within("#merge_venue_results") { find("div", text: "The Tote (melbourne)").click }
    click_button "Merge into this venue"

    expect(page).to have_content("Nothing was merged: a venue cannot be merged into itself")
    expect(Lml::Venue.exists?(@survivor.id)).to be(true)
  end

  # The whole point of the merge: the duplicate could not be deleted while it held these gigs, and
  # after the merge the survivor is the one they protect.
  it "leaves the gigs protecting the survivor instead" do
    visit "/admin/venues/#{@survivor.id}"
    pick_duplicate
    click_button "Merge into this venue"

    accept_confirm { click_link "Delete Venue" }

    expect(page).to have_content("The Tote still has 1 gig, so it was not deleted.")
  end
end
