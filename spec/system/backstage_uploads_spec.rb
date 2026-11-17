# frozen_string_literal: true

require "rails_helper"

describe "backstage uploads", type: :system do
  before do
    @previous_app_host = Capybara.app_host
    Capybara.app_host = BACKSTAGE_APP_HOST

    @password = "supersecret123"
    @admin = create(:lml_user, :admin, password: @password, password_confirmation: @password)
    @tote = create(:lml_venue, name: "The Tote", location: "melbourne", time_zone: "Australia/Melbourne")

    sign_in_as_admin
  end

  after { Capybara.app_host = @previous_app_host }

  def sign_in_as_admin
    visit "/backstage/login"
    fill_in "user_email", with: @admin.email
    fill_in "user_password", with: @password
    click_button "Sign in"

    raise "backstage sign in failed" unless page.has_no_css?("#user_password")
  end

  it "pastes gigs in against a venue it picks, and shows what landed" do
    visit "/backstage"
    within("nav") { click_on "Uploads" }
    click_on "New upload"

    find("input[placeholder='Type to search venues...']").fill_in(with: "tote")
    find("[data-autocomplete-target=results] div", text: "The Tote").click
    fill_in "Source", with: "pasted"
    fill_in "upload[content]", with: "name: Gut Health\ndate: #{(Date.current + 5).iso8601}\ntime: 20:00\n"
    click_button "Upload"

    expect(page).to have_text("Uploaded 1 gig")
    expect(page).to have_link("Gut Health")
    upload = Lml::Upload.order(:created_at).last
    expect(upload.user).to eq(@admin)
    expect(upload.venue).to eq(@tote)
    expect(Lml::Gig.find_by!(name: "Gut Health").venue).to eq(@tote)
  end

  it "switches between your uploads and everybody's" do
    Lml::Upload.create!(user: create(:lml_user), source: "lmb", venue: @tote, format: "clipper",
                        time_zone: "Australia/Melbourne", content: "name: Theirs\ndate: 2026-12-05\n")

    visit "/backstage/uploads"
    expect(page).to have_text("No uploads here yet.")

    click_on "Everyone's"
    expect(page).to have_link("lmb")

    click_on "Yours"
    expect(page).to have_text("No uploads here yet.")
  end
end
