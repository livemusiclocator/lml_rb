# frozen_string_literal: true

require "rails_helper"

describe "refreshing a venue from google", type: :system do
  before do
    @previous_app_host = Capybara.app_host
    Capybara.app_host = BACKSTAGE_APP_HOST

    @password = "supersecret123"
    @admin = create(:lml_user, :admin, password: @password, password_confirmation: @password)
    @venue = create(
      :lml_venue,
      name: "Tote",
      address: "71 Johnston St, Collingwood VIC 3066, Australia",
      google_place_id: "place-tote",
      address_components: { "postal_code" => "3066" },
      website: nil,
    )

    @place = {
      "id" => "place-tote",
      "displayName" => { "text" => "The Tote Hotel" },
      "formattedAddress" => "67-71 Johnston St, Collingwood VIC 3066, Australia",
      "shortFormattedAddress" => "67-71 Johnston St, Collingwood",
      "businessStatus" => "OPERATIONAL",
      "timeZone" => { "id" => "Australia/Melbourne" },
      "websiteUri" => "https://thetotehotel.com",
      "addressComponents" => [{ "types" => ["postal_code"], "shortText" => "3066", "longText" => "3066" }],
    }
    @details = stub_request(:get, %r{places\.googleapis\.com/v1/places/place-tote}).to_return(
      status: 200,
      body: @place.to_json,
    )

    visit "/backstage/login"
    fill_in "user_email", with: @admin.email
    fill_in "user_password", with: @password
    click_button "Sign in"
    raise "backstage sign in failed" unless page.has_no_css?("#user_password")
  end

  after { Capybara.app_host = @previous_app_host }

  it "shows what google changed, keeps what was rejected, and saves the rest" do
    visit "/backstage/venues/#{@venue.id}/edit"
    click_button "Refresh from Google"

    expect(page).to have_content("Filled in from Google")
    expect(page).to have_field("Address", with: "67-71 Johnston St, Collingwood")
    expect(page).to have_content("Was: 71 Johnston St, Collingwood VIC 3066, Australia")
    expect(page).to have_field("Website", with: "https://thetotehotel.com")
    expect(page).to have_field("Name", with: "The Tote Hotel")
    expect(page).to have_no_content("already a venue")

    find("p", text: "Was: Tote").click_button("Keep old")
    expect(page).to have_field("Name", with: "Tote")
    click_button "Save venue"

    expect(page).to have_content("Saved Tote.")
    expect(@venue.reload).to have_attributes(
      name: "Tote",
      address: "67-71 Johnston St, Collingwood",
      website: "https://thetotehotel.com",
      google_place: @place,
    )
    expect(@details.with { |request| !request.uri.query.to_s.include?("sessionToken") }).to have_been_requested
  end

  it "says so when google has nothing new" do
    @venue.update!(
      name: "The Tote Hotel",
      address: "67-71 Johnston St, Collingwood",
      postcode: "3066",
      website: "https://thetotehotel.com",
    )

    visit "/backstage/venues/#{@venue.id}/edit"
    click_button "Refresh from Google"

    expect(page).to have_content("Google has nothing new for this venue.")
    expect(page).to have_no_content("Was:")
  end

  it "goes from the venue page's disagreements to the refresh" do
    @venue.update!(google_place: @place, google_place_fetched_at: 1.day.ago)

    visit "/backstage/venues/#{@venue.id}"
    expect(page).to have_content("Google says differently")
    click_link "Refresh from Google"

    expect(page).to have_content("last checked 1 day ago")
    expect(page).to have_button("Refresh from Google")
  end
end
