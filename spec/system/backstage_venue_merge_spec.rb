# frozen_string_literal: true

require "rails_helper"

describe "merging venues in backstage", type: :system do
  before do
    @previous_app_host = Capybara.app_host
    Capybara.app_host = BACKSTAGE_APP_HOST

    @password = "supersecret123"
    @admin = create(:lml_user, :admin, password: @password, password_confirmation: @password)
    @place = { "id" => "place-pfr", "displayName" => { "text" => "PFR Lounge" } }
    @survivor = create(
      :lml_venue,
      name: "P.F.R Lounge",
      google_place_id: "place-pfr",
      address_components: { "postal_code" => "3065" },
      google_place: @place,
    )
    @duplicate = create(:lml_venue, name: "PFR Lounge", capacity: 120)
    @gig = create(:lml_gig, venue: @duplicate, name: "Old Gig", date: Date.current + 3)

    visit "/backstage/login"
    fill_in "user_email", with: @admin.email
    fill_in "user_password", with: @password
    click_button "Sign in"
    raise "backstage sign in failed" unless page.has_no_css?("#user_password")
  end

  after { Capybara.app_host = @previous_app_host }

  it "moves the duplicate's gigs onto the venue kept and deletes the duplicate" do
    visit "/backstage/venues/#{@survivor.id}"
    find_field("Duplicate venue").send_keys("PFR Lounge")
    find("[data-autocomplete-target=results] div", text: "PFR Lounge", exact_text: true).click

    accept_confirm { click_button "Merge into this venue" }

    expect(page).to have_content("Merged PFR Lounge into P.F.R Lounge. Moved 1 gig.")
    expect(page).to have_content("Old Gig")
    expect(@gig.reload.venue).to eq(@survivor)
    expect(Lml::Venue.exists?(@duplicate.id)).to be(false)
    expect(@survivor.reload).to have_attributes(capacity: 120, google_place: @place)
  end
end
