# frozen_string_literal: true

require "rails_helper"

# Deleting a venue used to take its gigs with it, and ActiveAdmin reports what it was asked to do
# rather than what happened, so both delete paths need driving through the browser: a request spec
# would not notice that the flash says one thing while the database says another.
describe "deleting a venue in admin", type: :system do
  before do
    @password = "supersecret123"
    @admin_user = Lml::AdminUser.create!(
      email: "venue_delete_spec@example.com",
      username: "deleter",
      password: @password,
      password_confirmation: @password,
      time_zone: "Australia/Melbourne",
    )

    sign_in_as_admin

    @venue = Lml::Venue.create!(name: "The Duplicate", location: "melbourne", time_zone: "Australia/Melbourne")
  end

  def sign_in_as_admin
    visit "/admin/login"
    fill_in "admin_user_email", with: @admin_user.email
    fill_in "admin_user_password", with: @password
    find("input[type=submit]").click

    raise "admin sign in failed" unless page.has_no_css?("#admin_user_password")
  end

  # A gig with a set on it is the case that used to raise a foreign key violation, and a gig
  # without one is the case that used to delete quietly, so both are worth a gig of their own.
  def add_gig(with_set:)
    gig = Lml::Gig.create!(name: "A gig", venue: @venue, date: Date.current)
    Lml::Set.create!(gig: gig, act: Lml::Act.create!(name: "A band")) if with_set
    gig
  end

  it "refuses to delete a venue whose gigs have sets, and says why" do
    gig = add_gig(with_set: true)

    visit "/admin/venues/#{@venue.id}"
    accept_confirm { click_link "Delete Venue" }

    expect(page).to have_content(
      "The Duplicate still has 1 gig, so it was not deleted. Move them to another venue first.",
    )
    expect(Lml::Venue.exists?(@venue.id)).to be(true)
    expect(Lml::Gig.exists?(gig.id)).to be(true)
  end

  it "refuses to delete a venue whose gigs have no sets, rather than deleting them" do
    gig = add_gig(with_set: false)

    visit "/admin/venues/#{@venue.id}"
    accept_confirm { click_link "Delete Venue" }

    expect(page).to have_content("The Duplicate still has 1 gig, so it was not deleted.")
    expect(Lml::Venue.exists?(@venue.id)).to be(true)
    expect(Lml::Gig.exists?(gig.id)).to be(true)
  end

  it "counts the gigs it is refusing over" do
    2.times { add_gig(with_set: false) }

    visit "/admin/venues/#{@venue.id}"
    accept_confirm { click_link "Delete Venue" }

    expect(page).to have_content("The Duplicate still has 2 gigs, so it was not deleted.")
  end

  it "deletes a venue once its gigs have been moved off it" do
    gig = add_gig(with_set: true)
    other = Lml::Venue.create!(name: "The Original", location: "melbourne", time_zone: "Australia/Melbourne")
    gig.update!(venue: other)

    visit "/admin/venues/#{@venue.id}"
    accept_confirm { click_link "Delete Venue" }

    expect(page).to have_content("Venue was successfully destroyed.")
    expect(Lml::Venue.exists?(@venue.id)).to be(false)
    expect(Lml::Gig.find(gig.id).venue).to eq(other)
  end

  # The batch action is a separate code path with its own message, and its own way of lying: it
  # used to count the ids it was handed rather than the venues it destroyed.
  it "deletes only the venues without gigs when a batch spans both" do
    add_gig(with_set: true)
    empty = Lml::Venue.create!(name: "The Empty", location: "melbourne", time_zone: "Australia/Melbourne")

    visit "/admin/venues"
    check "collection_selection_toggle_all"
    # ActiveAdmin's batch actions are a jQuery UI dialog of their own, not a native confirm, so
    # accept_confirm never sees anything - the OK button is a real button in the page.
    click_link "Batch Actions"
    click_link "Delete Selected"
    within(".active_admin_dialog") { click_button "OK" }

    expect(page).to have_content("Deleted 1 venue.")
    expect(page).to have_content("The Duplicate still has 1 gig, so it was not deleted.")
    expect(Lml::Venue.exists?(empty.id)).to be(false)
    expect(Lml::Venue.exists?(@venue.id)).to be(true)
  end
end
