# frozen_string_literal: true

require "rails_helper"

# A field is only wired up if the form renders it, the controller permits it and
# the show page reads it back. A request spec can prove the last two and still
# miss a name mismatch on the input, so this drives the real form.
describe "the venue LGA field", type: :system do
  before do
    @password = "supersecret123"
    @admin_user = Lml::AdminUser.create!(
      email: "venue_lga_spec@example.com",
      username: "lga",
      password: @password,
      password_confirmation: @password,
      time_zone: "Australia/Melbourne",
    )

    sign_in_as_admin
  end

  def sign_in_as_admin
    visit "/admin/login"
    fill_in "admin_user_email", with: @admin_user.email
    fill_in "admin_user_password", with: @password
    find("input[type=submit]").click

    raise "admin sign in failed" unless page.has_no_css?("#admin_user_password")
  end

  it "records an LGA on a new venue" do
    visit "/admin/venues/new"
    fill_in "lml_venue_name", with: "The Tote"
    select "Australia/Melbourne", from: "lml_venue_time_zone"
    fill_in "lml_venue_lga", with: "City of Yarra"
    find("input[type=submit]").click

    expect(page).to have_css("th", text: "LGA")
    expect(page).to have_content("City of Yarra")
    expect(Lml::Venue.find_by(name: "The Tote").lga).to eq("City of Yarra")
  end

  it "edits the LGA of an existing venue" do
    venue = create(:lml_venue, name: "The Curtin", lga: "City of Melbourne")

    visit "/admin/venues/#{venue.id}/edit"
    fill_in "lml_venue_lga", with: "City of Yarra"
    find("input[type=submit]").click

    expect(page).to have_content("City of Yarra")
    expect(venue.reload.lga).to eq("City of Yarra")
  end
end
