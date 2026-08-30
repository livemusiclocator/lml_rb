# frozen_string_literal: true

require "rails_helper"

# A request spec can prove the member action resolves a venue and still miss that nothing on the
# page reaches it - which is exactly how "Grant admin" shipped broken. So this clicks the button.
#
# ActiveAdmin 3.5 ships no rails-ujs, so `link_to method: :post` would be a GET that silently does
# nothing; the panel uses a real form, and this is what proves it.
describe "looking a venue up in google places", type: :system do
  BUTTON = "Look up in Google Places"

  before do
    @password = "supersecret123"
    @admin_user = Lml::AdminUser.create!(
      email: "venue_place_lookup_spec@example.com",
      username: "places",
      password: @password,
      password_confirmation: @password,
      time_zone: "Australia/Melbourne",
    )

    @venue = create(:lml_venue, name: "The Espy", address: "11 The Esplanade, St Kilda")

    sign_in_as_admin
  end

  def sign_in_as_admin
    visit "/admin/login"
    fill_in "admin_user_email", with: @admin_user.email
    fill_in "admin_user_password", with: @password
    find("input[type=submit]").click

    raise "admin sign in failed" unless page.has_no_css?("#admin_user_password")
  end

  def places_returning(*places)
    stub_request(:post, Lml::GooglePlacesApiClient::FIND_URL)
      .to_return(status: 200, body: { places: places }.to_json, headers: { "Content-Type" => "application/json" })
  end

  def espy_place(id: "placeespy")
    {
      id: id,
      displayName: { text: "Hotel Esplanade" },
      formattedAddress: "11 The Esplanade, St Kilda VIC 3182",
      businessStatus: "OPERATIONAL",
      timeZone: { id: "Australia/Melbourne" },
      location: { latitude: -37.8676, longitude: 144.9756 },
      addressComponents: [{ types: ["route"], shortText: "The Esplanade", longText: "The Esplanade" }],
    }
  end

  it "resolves the venue and shows what it found" do
    places_returning(espy_place)

    visit "/admin/venues/#{@venue.id}"
    click_on BUTTON

    expect(page).to have_content("Matched one place")
    expect(page).to have_content("placeespy")
    expect(@venue.reload.google_place_id).to eq("placeespy")
  end

  it "fills in the venue's blank columns from google" do
    places_returning(espy_place)

    visit "/admin/venues/#{@venue.id}"
    click_on BUTTON

    expect(@venue.reload.latitude).to eq(-37.8676)
  end

  it "leaves a column somebody has already researched alone" do
    @venue.update!(latitude: -37.0, longitude: 144.0)
    places_returning(espy_place)

    visit "/admin/venues/#{@venue.id}"
    click_on BUTTON

    expect(@venue.reload.latitude).to eq(-37.0)
  end

  it "says so on the page when google has nothing" do
    places_returning

    visit "/admin/venues/#{@venue.id}"
    click_on BUTTON

    expect(page).to have_content("did not settle on one place")
    # The marker is in a status_tag, which CSS uppercases.
    expect(page).to have_content(/no match/i)
  end

  it "says how many candidates there were when google offers a choice" do
    places_returning(espy_place(id: "one"), espy_place(id: "two"))

    visit "/admin/venues/#{@venue.id}"
    click_on BUTTON

    expect(page).to have_content(/ambiguous - 2 matches/i)
    expect(@venue.reload.address_components).to eq({})
  end

  it "closes the button once the venue has an answer, so a second click cannot spend again" do
    places_returning(espy_place)

    visit "/admin/venues/#{@venue.id}"
    click_on BUTTON

    expect(page).to have_css("input[type=submit][disabled][value='#{BUTTON}']")
  end

  it "closes the button on a venue whose lookup found nothing, not just a successful one" do
    @venue.update!(google_place_id: "no match")

    visit "/admin/venues/#{@venue.id}"

    expect(page).to have_css("input[type=submit][disabled][value='#{BUTTON}']")
  end

  it "reports a places outage rather than throwing a 500 at whoever clicked" do
    stub_request(:post, Lml::GooglePlacesApiClient::FIND_URL).to_return(status: 403, body: "api not enabled")

    visit "/admin/venues/#{@venue.id}"
    click_on BUTTON

    expect(page).to have_content("Places API error")
    expect(@venue.reload.google_place_id).to be_nil
  end
end
