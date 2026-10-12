# frozen_string_literal: true

require "rails_helper"

describe "backstage venues", type: :system do
  before do
    @previous_app_host = Capybara.app_host
    Capybara.app_host = BACKSTAGE_APP_HOST

    @password = "supersecret123"
    @manager = create(:lml_user, password: @password, password_confirmation: @password)
    @venue = create(:lml_venue, name: "The Tote")
    Lml::VenueManager.create!(user: @manager, venue: @venue)
    create(:lml_gig, venue: @venue, name: "Saturday night gig", date: Date.current + 3)

    sign_in_as_manager
  end

  after { Capybara.app_host = @previous_app_host }

  def sign_in_as_manager
    visit "/backstage/login"
    fill_in "user_email", with: @manager.email
    fill_in "user_password", with: @password
    click_button "Sign in"

    raise "backstage sign in failed" unless page.has_no_css?("#user_password")
  end

  it "reaches a venue's gigs from the nav" do
    click_on "My Venues"
    click_on "The Tote"

    expect(page).to have_css("h1", text: "The Tote")
    expect(page).to have_content("Saturday night gig")
  end

  it "reaches a venue's gigs from the dashboard" do
    within("main") { click_on "The Tote" }

    expect(page).to have_css("h1", text: "The Tote")
  end

  it "lets an admin find and open a venue they do not manage" do
    @manager.update!(admin: true)
    create(:lml_venue, name: "The Gasometer")

    click_on "Venues"
    fill_in "q", with: "gaso"
    click_button "Search"
    click_on "The Gasometer"

    expect(page).to have_css("h1", text: "The Gasometer")
    expect(page).to have_link("Add a gig")
  end
end
