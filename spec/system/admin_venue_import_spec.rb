# frozen_string_literal: true

require "rails_helper"

# The submit button is a real form rather than a link, because ActiveAdmin 3.5
# ships no rails-ujs and `link_to ..., method: :post` is silently a GET. Only a
# browser can tell the difference, so this clicks the thing.
describe "the venue import page", type: :system do
  before do
    @password = "supersecret123"
    @admin_user = Lml::AdminUser.create!(
      email: "venue_import_system_spec@example.com",
      username: "importer",
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

  it "is not linked from the menu" do
    visit "/admin/dashboard"

    expect(page).to have_no_link("Venue Import")
  end

  it "is reachable by knowing the url" do
    visit "/admin/venue_import"

    expect(page).to have_css("h2", text: "Import venues from a Google Sheet")
  end

  # Stubbed rather than left to make a real call: a browser test that talks to
  # Google would be slow, billable and flaky. What is being proved here is that
  # the click reaches the action at all - the button is a form, not a link that
  # ActiveAdmin would render as a silent GET.
  it "runs the import when the button is clicked, and says what happened" do
    allow(Lml::VenueImport).to receive(:call).and_return({ "created" => 2, "ambiguous" => 1 })

    visit "/admin/venue_import"
    fill_in "sheet_url", with: "https://docs.google.com/spreadsheets/d/abc123DEF/edit"
    click_on "Import venues"

    expect(page).to have_content("Imported: 2 created, 1 ambiguous.")
  end

  it "puts the reason on screen when the import fails" do
    allow(Lml::VenueImport).to receive(:call).and_raise(StandardError, "The caller does not have permission")

    visit "/admin/venue_import"
    fill_in "sheet_url", with: "https://docs.google.com/spreadsheets/d/abc123DEF/edit"
    click_on "Import venues"

    expect(page).to have_content("The caller does not have permission")
  end

  it "asks for a url when the field is empty" do
    visit "/admin/venue_import"

    click_on "Import venues"

    expect(page).to have_content("Paste the spreadsheet's URL first")
  end

  it "keeps the url in the field after a run" do
    allow(Lml::VenueImport).to receive(:call).and_return({ "created" => 1 })

    visit "/admin/venue_import"

    fill_in "sheet_url", with: "https://docs.google.com/spreadsheets/d/abc123DEF/edit"
    click_on "Import venues"

    expect(page).to have_field("sheet_url", with: "https://docs.google.com/spreadsheets/d/abc123DEF/edit")
  end
end
