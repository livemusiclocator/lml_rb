# frozen_string_literal: true

require "rails_helper"

describe "backstage acts", type: :system do
  before do
    @previous_app_host = Capybara.app_host
    Capybara.app_host = BACKSTAGE_APP_HOST

    @password = "supersecret123"
    @admin = create(:lml_user, :admin, password: @password, password_confirmation: @password)
    create(:lml_act, name: "Amyl and the Sniffers")

    visit "/backstage/login"
    fill_in "user_email", with: @admin.email
    fill_in "user_password", with: @password
    click_button "Sign in"
    raise "backstage sign in failed" unless page.has_no_css?("#user_password")
  end

  after { Capybara.app_host = @previous_app_host }

  it "adds an act" do
    click_on "Acts"
    click_on "Add an act"
    fill_in "Name", with: "Gut Health"
    fill_in "Genres", with: "post-punk"
    click_button "Add act"

    expect(page).to have_content("Added Gut Health.")
    expect(Lml::Act.find_by!(name: "Gut Health").genres).to eq(["post-punk"])
  end

  it "finds and edits an act" do
    click_on "Acts"
    fill_in "q", with: "amyl"
    click_button "Search"
    click_on "Amyl and the Sniffers"
    fill_in "Instagram handle", with: "amylandthesniffers"
    click_button "Save act"

    expect(page).to have_content("Saved Amyl and the Sniffers.")
    expect(Lml::Act.sole.instagram).to eq("amylandthesniffers")
  end
end
