# frozen_string_literal: true

require "rails_helper"

# The "Available Venues (Not Assigned)" panel was removed from here: it listed an arbitrary 50
# unassigned venues with no ordering, and assigning is done from the venue itself. This covers what
# is left, which had no system spec of its own, and would catch the show page failing to render.
describe "an admin user's assigned venues", type: :system do
  before do
    @password = "supersecret123"
    @admin_user = Lml::AdminUser.create!(
      email: "admin_user_venues_spec@example.com",
      username: "assigner",
      password: @password,
      password_confirmation: @password,
      time_zone: "Australia/Melbourne",
    )

    sign_in_as_admin

    @assigned = Lml::Venue.create!(
      name: "The Tote", location: "melbourne", time_zone: "Australia/Melbourne", admin_user: @admin_user,
    )
    @unassigned = Lml::Venue.create!(name: "The Corner", location: "melbourne", time_zone: "Australia/Melbourne")

    visit "/admin/admin_users/#{@admin_user.id}"
  end

  def sign_in_as_admin
    visit "/admin/login"
    fill_in "admin_user_email", with: @admin_user.email
    fill_in "admin_user_password", with: @password
    find("input[type=submit]").click

    raise "admin sign in failed" unless page.has_no_css?("#admin_user_password")
  end

  it "lists the venues assigned to them" do
    expect(page).to have_css("h3", text: "Assigned Venues")
    expect(page).to have_link("The Tote")
  end

  it "no longer offers a list of venues to assign from" do
    expect(page).to have_no_content("Available Venues")
    expect(page).to have_no_button("Assign Selected")
    # The unassigned venue has no business being listed on this page at all now.
    expect(page).to have_no_link("The Corner")
  end

  it "unassigns a venue that is ticked" do
    check "venue_ids[]"
    accept_confirm { click_button "Unassign Selected" }

    expect(page).to have_content("1 venue(s) unassigned.")
    expect(@assigned.reload.admin_user).to be_nil
  end
end
