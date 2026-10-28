# frozen_string_literal: true

require "rails_helper"

describe "backstage proposals", type: :system do
  before do
    @previous_app_host = Capybara.app_host
    Capybara.app_host = BACKSTAGE_APP_HOST

    @password = "supersecret123"
    @researcher = create(:lml_user, password: @password, password_confirmation: @password)
    @venue = create(:lml_venue, name: "The Tote", location: "melbourne")

    visit "/backstage/login"
    fill_in "user_email", with: @researcher.email
    fill_in "user_password", with: @password
    click_button "Sign in"
    raise "backstage sign in failed" unless page.has_no_css?("#user_password")
  end

  after { Capybara.app_host = @previous_app_host }

  it "proposes a new gig with its set list" do
    visit "/backstage/proposals/new?target_type=new_gig"
    fill_in "proposal[proposed_attributes][name]", with: "Gut Health"
    fill_in "proposal[proposed_attributes][date]", with: Date.current + 5
    find("input[placeholder='Type to search venues...']").fill_in(with: "tote")
    find("[data-autocomplete-target=results] div", text: "The Tote").click
    within(all("[data-line-list-row]")[0]) do
      fill_in "Act - new or existing", with: "Gut Health"
      fill_in "Start", with: "9pm"
    end
    click_button "+ Add a set"
    within(all("[data-line-list-row]")[1]) { fill_in "Act - new or existing", with: "Support Act" }
    click_button "Submit proposal"

    expect(page).to have_no_css("[data-line-list-row]")
    expect(Lml::Proposal.sole.proposed_attributes["set_list"]).to eq("Gut Health | 9:00pm\nSupport Act")
  end

  # A genre change on its own used to be dropped, leaving an empty proposal.
  it "proposes new genres for a gig" do
    gig = create(:lml_gig, venue: @venue, name: "Gut Health", date: Date.current + 5)
    visit "/backstage/proposals/new?target_type=Lml::Gig"
    find("input[placeholder='Type to search gigs...']").fill_in(with: "gut")
    find("[data-autocomplete-target=results] div", text: "Gut Health").click
    genre_rows = find_field("proposal_genre_tag_list", visible: :all)
      .ancestor("[data-controller=line-list]").all("[data-line-list-row]")
    within(genre_rows[0]) { fill_in "Genre", with: "post-punk" }
    click_button "Submit proposal"

    expect(page).to have_no_css("[data-line-list-row]")
    proposal = Lml::Proposal.sole
    expect(proposal.target).to eq(gig)
    expect(proposal.proposed_attributes).to eq("genre_tag_list" => "post-punk")
  end
end
