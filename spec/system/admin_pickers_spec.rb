# frozen_string_literal: true

require "rails_helper"

# These pickers are javascript, so request specs cannot see them at all. That
# blind spot is not hypothetical: the price form asked for "lml_set_gig" element
# ids on a form that renders "lml_price_gig" ones, so its picker never attached
# to anything and nothing ever failed. Every example here needs a real browser
# to be capable of failing.
#
# The set and price admin pages are slated for removal in favour of editing sets
# and prices on the gig page, so they are deliberately not covered here.
describe "admin autocomplete pickers", type: :system do
  before do
    @password = "supersecret123"
    @admin_user = Lml::AdminUser.create!(
      email: "admin_pickers_spec@example.com",
      username: "picker",
      password: @password,
      password_confirmation: @password,
      time_zone: "Australia/Melbourne",
    )

    @venue = create(:lml_venue, name: "The Tote", location: "melbourne")
    @act = create(:lml_act, name: "Amyl and the Sniffers", country: "Australia")

    sign_in_as_admin
  end

  # Capybara's predicates wait, so this also synchronises on the redirect before
  # an example starts poking at a form that has not arrived yet.
  def sign_in_as_admin
    visit "/admin/login"
    fill_in "admin_user_email", with: @admin_user.email
    fill_in "admin_user_password", with: @password
    find("input[type=submit]").click

    raise "admin sign in failed" unless page.has_no_css?("#admin_user_password")
  end

  # The gig form supplies no results element of its own, so this also covers
  # attachSearchAutocomplete creating one on demand.
  describe "the gig form" do
    before { visit "/admin/gigs/new" }

    it "suggests matching venues" do
      fill_in "lml_gig_venue_label", with: "tote"

      expect(page).to have_css("#lml_gig_venue_results", text: "The Tote (melbourne)")
    end

    it "records the chosen venue's id" do
      fill_in "lml_gig_venue_label", with: "tote"
      within("#lml_gig_venue_results") { find("div", text: "The Tote").click }

      expect(find("#lml_gig_venue_id", visible: :hidden).value).to eq(@venue.id)
    end

    it "matches on a location the name does not contain" do
      fill_in "lml_gig_venue_label", with: "melbourne"

      expect(page).to have_css("#lml_gig_venue_results", text: "The Tote (melbourne)")
    end

    it "suggests nothing for a query that matches nothing" do
      fill_in "lml_gig_venue_label", with: "nowhere"

      expect(page).to have_no_css("#lml_gig_venue_results div")
    end

    it "suggests nothing for a single character" do
      fill_in "lml_gig_venue_label", with: "t"

      expect(page).to have_no_css("#lml_gig_venue_results div")
    end
  end

  describe "the upload form" do
    it "suggests matching venues" do
      visit "/admin/uploads/new"
      fill_in "lml_upload_venue_label", with: "tote"

      expect(page).to have_css("#lml_upload_venue_results", text: "The Tote (melbourne)")
    end
  end

  # The sidebar that grants a backstage user manager access. This is the picker
  # that reads /acts/search, so it is the one an act payload change can break.
  describe "the promote to manager sidebar" do
    before do
      @user = Lml::User.create!(
        email: "backstage_user@example.com",
        display_name: "Backstage Betty",
        password: @password,
        password_confirmation: @password,
        confirmed_at: Time.current,
      )
      visit "/admin/users/#{@user.id}"
    end

    it "suggests matching acts" do
      fill_in "act_label", with: "amyl"

      expect(page).to have_css("#grant_act_results", text: "Amyl and the Sniffers (Australia)")
    end

    it "records the chosen act's id" do
      fill_in "act_label", with: "amyl"
      within("#grant_act_results") { find("div", text: "Amyl and the Sniffers").click }

      expect(find("#grant_act_id", visible: :hidden).value).to eq(@act.id)
    end

    it "suggests matching venues" do
      fill_in "venue_label", with: "tote"

      expect(page).to have_css("#grant_venue_results", text: "The Tote (melbourne)")
    end
  end
end
