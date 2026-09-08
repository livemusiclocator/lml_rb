# frozen_string_literal: true

require "rails_helper"

# The venue version of this is spec/system/admin_venue_delete_spec.rb. Acts got here by a different
# route - Lml::Act#sets carried no dependent at all, so the sets foreign key refused and the admin
# showed a 500 - but the control being proved is the same one.
describe "deleting an act in admin", type: :system do
  before do
    @password = "supersecret123"
    @admin_user = Lml::AdminUser.create!(
      email: "act_delete_spec@example.com",
      username: "actdel",
      password: @password,
      password_confirmation: @password,
      time_zone: "Australia/Melbourne",
    )

    sign_in_as_admin

    @act = Lml::Act.create!(name: "Amyl and the Sniffers")
    @venue = Lml::Venue.create!(name: "The Tote", location: "melbourne", time_zone: "Australia/Melbourne")
  end

  def sign_in_as_admin
    visit "/admin/login"
    fill_in "admin_user_email", with: @admin_user.email
    fill_in "admin_user_password", with: @password
    find("input[type=submit]").click

    raise "admin sign in failed" unless page.has_no_css?("#admin_user_password")
  end

  def add_set
    gig = Lml::Gig.create!(name: "A gig", venue: @venue, date: Date.current)
    Lml::Set.create!(gig: gig, act: @act)
  end

  it "refuses to delete an act that is still on a bill, and says why" do
    set = add_set

    visit "/admin/acts/#{@act.id}"
    accept_confirm { click_link "Delete Act" }

    expect(page).to have_content(
      "Amyl and the Sniffers is still on the bill for 1 gig, so it was not deleted. " \
      "Take it off those line ups first.",
    )
    expect(Lml::Act.exists?(@act.id)).to be(true)
    # The whole point: the set belongs to someone else's gig and stays on it.
    expect(Lml::Set.exists?(set.id)).to be(true)
  end

  it "counts the gigs it is refusing over" do
    2.times { add_set }

    visit "/admin/acts/#{@act.id}"
    accept_confirm { click_link "Delete Act" }

    expect(page).to have_content("is still on the bill for 2 gigs")
  end

  # destroy runs its callbacks in a transaction, so an aborted delete must not have taken the
  # manager rows declared above the sets association with it.
  it "leaves the act's managers alone when the delete is refused" do
    add_set
    user = Lml::User.create!(
      email: "act_manager@example.com", password: @password, confirmed_at: Time.current,
    )
    Lml::ActManager.create!(user: user, act: @act)

    visit "/admin/acts/#{@act.id}"
    accept_confirm { click_link "Delete Act" }

    expect(@act.reload.managers).to eq([user])
  end

  it "deletes an act that is not on any bill" do
    visit "/admin/acts/#{@act.id}"
    accept_confirm { click_link "Delete Act" }

    expect(page).to have_content("Act was successfully destroyed.")
    expect(Lml::Act.exists?(@act.id)).to be(false)
  end

  it "deletes only the acts without sets when a batch spans both" do
    add_set
    spare = Lml::Act.create!(name: "Nobody At All")

    visit "/admin/acts"
    check "collection_selection_toggle_all"
    # ActiveAdmin's batch actions use a jQuery UI dialog, not a native confirm.
    click_link "Batch Actions"
    click_link "Delete Selected"
    within(".active_admin_dialog") { click_button "OK" }

    expect(page).to have_content("Deleted 1 act.")
    expect(page).to have_content("Amyl and the Sniffers is still on the bill for 1 gig")
    expect(Lml::Act.exists?(spare.id)).to be(false)
    expect(Lml::Act.exists?(@act.id)).to be(true)
  end
end
