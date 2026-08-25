# frozen_string_literal: true

require "rails_helper"

# The about section used to send people to a google doc that documented three
# endpoints which no longer answer. It now links to /docs, which is a route that
# only exists on www because this commit added it. A request spec can prove the
# endpoint renders; only a browser can prove the anchor on the page arrives at it.
describe "api documentation link", type: :system do
  before do
    @previous_app_host = Capybara.app_host
    Capybara.app_host = WEB_APP_HOST
  end

  after { Capybara.app_host = @previous_app_host }

  it "reaches the docs from the about section" do
    visit "/about/api-stats-and-data"

    click_link "API Documentation"

    expect(page).to have_current_path("/docs")
    expect(page).to have_css("h2", text: "Endpoints")
  end

  it "reaches the docs from the how to use page" do
    visit "/about/how-to-use-livemusiclocator"

    click_link "here"

    expect(page).to have_current_path("/docs")
    expect(page).to have_css("h2", text: "Endpoints")
  end
end
