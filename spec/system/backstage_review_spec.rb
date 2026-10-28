# frozen_string_literal: true

require "rails_helper"

# The three buttons on a review screen share one form and say which they are by
# the decision they submit, so each one is clicked here: a request spec can post
# decision=hide all day without proving the Hide button sends it.
describe "backstage review", type: :system do
  before do
    @previous_app_host = Capybara.app_host
    Capybara.app_host = BACKSTAGE_APP_HOST

    @password = "supersecret123"
    @admin = create(:lml_user, :admin, password: @password, password_confirmation: @password)
    @tote = create(:lml_venue, name: "The Tote")
    # The queue starts from the admin's own uploads.
    @upload = Lml::Upload.create!(user: @admin, source: "research-markryall", venue: @tote, format: "clipper",
                                  time_zone: "Australia/Melbourne", content: "")
    @dole = create(:lml_gig, name: "DOLE NIGHT w/ Contact Sport + Brodown", date: Date.current + 1, venue: @tote,
                             source: "research-markryall", upload: @upload, proposed_acts: ["Contact Sport", "Brodown"],
                             proposed_genre_tags: ["punk"])
    @karaoke = create(:lml_gig, name: "Kickarse Karaoke", date: Date.current + 2, venue: @tote,
                                source: "research-markryall", upload: @upload)

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

  def act_names
    find_field("gig_set_list", visible: :all).ancestor("[data-controller=line-list]")
                                             .all("[data-field=act]").map(&:value)
  end

  it "starts from the dashboard and confirms the suggested lineup" do
    visit "/backstage"
    click_on "Review gigs"
    click_on "Start reviewing"

    expect(page).to have_css("h1", text: "DOLE NIGHT w/ Contact Sport + Brodown")
    expect(act_names).to eq(["Contact Sport", "Brodown"])

    fill_in "Gig name / headliner", with: "Contact Sport"
    click_button "Save & mark checked"

    expect(page).to have_css("h1", text: "Kickarse Karaoke")
    @dole.reload
    expect(@dole.name).to eq("Contact Sport")
    expect(@dole.sets.map { |set| set.act.name }).to contain_exactly("Contact Sport", "Brodown")
    expect(@dole.genre_tags).to eq(["punk"])
    expect(@dole).to be_checked
  end

  it "switches between your uploads and everybody's" do
    other = create(:lml_venue, name: "Golden Vine Hotel")
    create(:lml_gig, name: "Andrew Swift", date: Date.current + 3, venue: other)

    visit "/backstage/reviews"
    expect(page).to have_link("The Tote")
    expect(page).to have_no_link("Golden Vine Hotel")

    click_on "Everyone's"
    expect(page).to have_link("Golden Vine Hotel")

    click_on "Your uploads"
    expect(page).to have_no_link("Golden Vine Hotel")
  end

  it "hides a gig that is not one" do
    visit "/backstage/reviews/#{@karaoke.id}"
    click_button "Hide - not a gig"

    expect(page).to have_text("Hid Kickarse Karaoke")
    expect(@karaoke.reload).to be_hidden
    expect(@karaoke).to be_checked
  end

  it "skips a gig without touching it" do
    visit "/backstage/reviews/#{@dole.id}"
    click_button "Skip"

    expect(page).to have_css("h1", text: "Kickarse Karaoke")
    expect(@dole.reload).not_to be_checked
    expect(@dole.sets).to be_empty
  end
end
