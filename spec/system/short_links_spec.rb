# frozen_string_literal: true

require "rails_helper"

# Every page that shows a short link has a button copying it. Headless Chrome's
# clipboard needs permissions a spec cannot rely on, so each example swaps
# writeText for a stub that keeps what it was given - the button still has to
# be wired to the right url for anything to land there.
describe "copying short links", type: :system do
  before do
    @gig = create(:lml_gig, name: "Saturday night gig", date: Date.current + 3)
    @venue = @gig.venue
    @act = create(:lml_act, name: "The Drones")
  end

  def stub_clipboard
    page.execute_script("navigator.clipboard.writeText = async (text) => { window.copied = text }")
  end

  def copied
    page.evaluate_script("window.copied")
  end

  describe "in backstage" do
    before do
      @previous_app_host = Capybara.app_host
      Capybara.app_host = BACKSTAGE_APP_HOST

      @password = "supersecret123"
      @user = create(:lml_user, password: @password, password_confirmation: @password, admin: true)
      visit "/backstage/login"
      fill_in "user_email", with: @user.email
      fill_in "user_password", with: @password
      click_button "Sign in"
      raise "backstage sign in failed" unless page.has_no_css?("#user_password")
    end

    after { Capybara.app_host = @previous_app_host }

    it "copies a venue's link from its page" do
      visit "/backstage/venues/#{@venue.id}"
      stub_clipboard
      within("main > div:first-child") { click_button "Copy link" }

      expect(page).to have_button("Copied!")
      expect(copied).to eq(@venue.short_url)
    end

    it "copies a gig's link from the venue's list of gigs" do
      visit "/backstage/venues/#{@venue.id}"
      stub_clipboard
      click_button "Copy link to Saturday night gig"

      expect(page).to have_button("Copied!")
      expect(copied).to eq(@gig.short_url)
    end

    it "copies a gig's link from its edit page" do
      visit "/backstage/gigs/#{@gig.id}/edit"
      stub_clipboard
      click_button "Copy link"

      expect(copied).to eq(@gig.short_url)
    end

    it "copies an act's link from its edit page" do
      visit "/backstage/acts/#{@act.id}/edit"
      stub_clipboard
      click_button "Copy link"

      expect(copied).to eq(@act.short_url)
    end
  end

  describe "in admin" do
    before do
      @password = "supersecret123"
      @admin_user = Lml::SuperAdmin.create!(
        email: "short_links_spec@example.com",
        username: "sharer",
        password: @password,
        password_confirmation: @password,
        time_zone: "Australia/Melbourne",
      )
      visit "/admin/login"
      fill_in "admin_user_email", with: @admin_user.email
      fill_in "admin_user_password", with: @password
      find("input[type=submit]").click
      raise "admin sign in failed" unless page.has_no_css?("#admin_user_password")
    end

    it "copies each kind of record's link from its page" do
      { "gigs" => @gig, "venues" => @venue, "acts" => @act }.each do |path, record|
        visit "/admin/#{path}/#{record.id}"
        stub_clipboard
        click_button "Copy link"

        expect(page).to have_button("Copied!")
        expect(copied).to eq(record.short_url)
      end
    end
  end
end
