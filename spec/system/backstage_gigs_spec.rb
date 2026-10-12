# frozen_string_literal: true

require "rails_helper"

describe "backstage gigs", type: :system do
  before do
    @previous_app_host = Capybara.app_host
    Capybara.app_host = BACKSTAGE_APP_HOST

    @password = "supersecret123"
    @manager = create(:lml_user, password: @password, password_confirmation: @password)
    @venue = create(:lml_venue, name: "The Tote")
    Lml::VenueManager.create!(user: @manager, venue: @venue)

    sign_in_as_manager
    visit "/backstage/venues/#{@venue.id}"
  end

  after { Capybara.app_host = @previous_app_host }

  def sign_in_as_manager
    visit "/backstage/login"
    fill_in "user_email", with: @manager.email
    fill_in "user_password", with: @password
    click_button "Sign in"

    raise "backstage sign in failed" unless page.has_no_css?("#user_password")
  end

  it "adds a gig to a venue they manage" do
    click_on "Add a gig"
    fill_in "Gig name / headliner", with: "Gut Health"
    fill_in "Date", with: Date.current + 5
    fill_in "Set list", with: "Gut Health\nSupport Act"
    click_button "Add gig"

    expect(page).to have_content("Added Gut Health.")
    expect(page).to have_content("Gut Health, Support Act")
    expect(@venue.gigs.sole.date).to eq(Date.current + 5)
  end

  # A 422 render, not a redirect - the case Turbo has to be happy to display.
  it "shows what is missing when the gig cannot be saved" do
    click_on "Add a gig"
    fill_in "Date", with: Date.current + 5
    # The browser would stop a blank required field before it ever got to us.
    page.execute_script("document.getElementById('gig_name').removeAttribute('required')")
    click_button "Add gig"

    expect(page).to have_content("Name can't be blank")
    expect(page).to have_field("Date", with: (Date.current + 5).iso8601)
  end
end
