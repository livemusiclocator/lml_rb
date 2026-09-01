# frozen_string_literal: true

require "rails_helper"

# The coverage panel is arbre, and arbre fails by rendering nothing rather than
# by raising, so a model spec proving the numbers cannot prove the dashboard
# shows them. The link out to the unserved venues is a ransack filter, which is
# the other thing that silently does nothing when the predicate is wrong.
describe "the admin dashboard coverage panel", type: :system do
  before do
    @password = "supersecret123"
    @admin_user = Lml::AdminUser.create!(
      email: "coverage_spec@example.com",
      username: "coverage",
      password: @password,
      password_confirmation: @password,
      time_zone: "Australia/Melbourne",
    )

    %w[anywhere melbourne brisbane].each do |identifier|
      Web::Location.create!(
        internal_identifier: identifier,
        name: identifier.titleize,
        latitude: -37.8,
        longitude: 144.9,
      )
    end
    Web::ExplorerConfig.create!(
      edition_id: "main",
      selectable_locations: %w[anywhere melbourne brisbane],
    )

    @tote = create(:lml_venue, name: "The Tote", location: "Melbourne")
    create(:lml_venue, name: "The Silent", location: "Melbourne")
    create(:lml_venue, name: "The Zoo", location: "brisbane")
    @stranded = create(:lml_venue, name: "The Lost", location: "St Kilda")
    create(:lml_gig, venue: @tote, date: Date.current - 30)

    sign_in_as_admin
  end

  def sign_in_as_admin
    visit "/admin/login"
    fill_in "admin_user_email", with: @admin_user.email
    fill_in "admin_user_password", with: @password
    find("input[type=submit]").click

    raise "admin sign in failed" unless page.has_no_css?("#admin_user_password")
  end

  def coverage_row(name)
    find("tr", text: /\A#{Regexp.escape(name)}/)
  end

  # Venues, profiling over 12 months, profiling over 90 days, gigs a week.
  def coverage_figures(name)
    coverage_row(name).all("td").map(&:text)
  end

  it "reports the Victorian totals and leaves an interstate region out of them" do
    visit "/admin"

    expect(coverage_figures("Melbourne")).to eq(["Melbourne", "2", "1", "1", "0.0"])
    expect(coverage_row("Brisbane")).to have_content("outside Victoria")
    expect(coverage_figures("Victoria")).to eq(["Victoria", "2", "1", "1", "0.0"])
  end

  it "sums the headline across the Victorian regions only" do
    visit "/admin"

    expect(page).to have_content("Across Victoria we hold 2 venues")
    expect(page).to have_content("profiling gigs at 1 of them")
  end

  it "says how many locations it left off the end of a long tail" do
    12.times { |n| create(:lml_venue, name: "Venue #{n}", location: "town #{n}") }

    visit "/admin"

    expect(page).to have_content("and 3 more locations")
  end

  it "lists a location no live region serves, and filters the venues down to it" do
    visit "/admin"

    expect(page).to have_content("Venues no live region serves")
    click_link "st kilda"

    expect(page).to have_content(@stranded.name)
    expect(page).to have_no_content(@tote.name)
  end
end
