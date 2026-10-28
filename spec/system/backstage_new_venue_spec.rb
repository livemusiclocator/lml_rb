# frozen_string_literal: true

require "rails_helper"

describe "adding a venue from backstage", type: :system do
  before do
    @previous_app_host = Capybara.app_host
    Capybara.app_host = BACKSTAGE_APP_HOST

    @password = "supersecret123"
    @admin = create(:lml_user, :admin, password: @password, password_confirmation: @password)

    @place = {
      "id" => "place-tote",
      "displayName" => { "text" => "The Tote Hotel" },
      "formattedAddress" => "71 Johnston St, Collingwood VIC 3066",
      "businessStatus" => "OPERATIONAL",
      "timeZone" => { "id" => "Australia/Melbourne" },
      "location" => { "latitude" => -37.7986, "longitude" => 144.9876 },
      "websiteUri" => "https://thetotehotel.com",
      "googleMapsUri" => "https://maps.google.com/?cid=3264005606005329900&g_mp=Cidnb29n",
      "nationalPhoneNumber" => "(03) 9419 5320",
      "addressComponents" => [{ "types" => ["postal_code"], "shortText" => "3066", "longText" => "3066" }],
    }
    @autocomplete = stub_request(:post, Lml::GooglePlacesApiClient::AUTOCOMPLETE_URL).to_return(
      status: 200,
      body: {
        suggestions: [
          {
            placePrediction: {
              placeId: "place-tote",
              text: { text: "The Tote Hotel, Collingwood" },
            },
          },
        ],
      }.to_json,
    )
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

  it "fills the venue in from the google place picked" do
    click_on "Venues"
    click_on "Add a venue"
    # Typed rather than fill_in, which blurs the box and so closes the search.
    find_field("Find it on Google").send_keys("tote")
    find("[data-autocomplete-target=results] div", text: "The Tote Hotel, Collingwood").click

    expect(page).to have_content("Filled in from Google")
    expect(page).to have_field("Name", with: "The Tote Hotel")
    expect(page).to have_field("Address", with: "71 Johnston St, Collingwood VIC 3066")
    expect(page).to have_field("Website", with: "https://thetotehotel.com")
    expect(page).to have_field("Map link", with: "https://maps.google.com/?cid=3264005606005329900")
    fill_in "Location", with: "melbourne"
    click_button "Add venue"

    expect(page).to have_content("Added The Tote Hotel.")
    venue = Lml::Venue.sole
    expect(venue.google_place).to eq(@place)
    expect(venue.postcode).to eq("3066")
    expect(venue.phone).to eq("(03) 9419 5320")
    # One session token, sent with the suggestions and spent on the details.
    expect(
      @autocomplete.with do |request|
        JSON.parse(request.body)["sessionToken"].present?
      end,
    ).to have_been_requested.at_least_once
    expect(@details.with(query: hash_including("sessionToken"))).to have_been_requested
  end

  # Chrome counts *.localhost as a secure origin, so the specs do too; a dev host
  # over plain http in another browser is not, and has no crypto.randomUUID.
  it "fills the venue in where the page is not a secure origin" do
    page.driver.browser.page.command(
      "Page.addScriptToEvaluateOnNewDocument",
      source: "delete Crypto.prototype.randomUUID",
    )
    visit "/backstage/venues/new"
    find_field("Find it on Google").send_keys("tote")
    find("[data-autocomplete-target=results] div", text: "The Tote Hotel, Collingwood").click

    expect(page).to have_field("Name", with: "The Tote Hotel")
    expect(@details.with(query: hash_including("sessionToken" => /\A\h{8}-\h{4}-4\h{3}-[89ab]\h{3}-\h{12}\z/)))
      .to have_been_requested
  end
end
