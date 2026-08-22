# frozen_string_literal: true

require "rails_helper"

# The secret is shown once, from the create response, so that it never goes near
# the flash or a cookie. That makes the whole feature dependent on how the
# browser handles a 200 to a form POST - and Turbo discards one, which shipped a
# page that created tokens and threw the secret away unseen. A request spec
# cannot see that. This needs a real browser to be capable of failing.
describe "backstage api tokens", type: :system do
  before do
    @previous_app_host = Capybara.app_host
    Capybara.app_host = BACKSTAGE_APP_HOST

    @password = "supersecret123"
    @admin = create(:lml_user, :admin, email: "token_system_spec@example.com",
                                       password: @password, password_confirmation: @password,)

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

  it "offers the token page in the nav" do
    click_on "API Tokens"

    expect(page).to have_css("h1", text: "Admin API tokens")
  end

  describe "issuing a token" do
    before { visit "/backstage/api_tokens" }

    it "shows the secret on the page after issuing it" do
      fill_in "name", with: "Import script"
      click_on "Issue token"

      expect(page).to have_content(/lml_admin_[A-Za-z0-9_-]+/)
    end

    it "shows a secret that actually authenticates, not a truncated one" do
      fill_in "name", with: "Import script"
      click_on "Issue token"

      secret = page.text[/lml_admin_[A-Za-z0-9_-]+/]
      expect(Lml::ApiToken.authenticate(secret)).to eq(Lml::ApiToken.last)
    end

    it "lists the new token straight away" do
      fill_in "name", with: "Import script"
      click_on "Issue token"

      expect(page).to have_css("td", text: "Import script")
      expect(page).to have_css("span", text: "Active")
    end

    it "applies the chosen expiry" do
      fill_in "name", with: "Import script"
      select "In 90 days", from: "expires_in_days"
      click_on "Issue token"

      expect(Lml::ApiToken.last.expires_at).to be_between(89.days.from_now, 91.days.from_now)
    end

    it "says why a nameless token was refused" do
      click_on "Issue token"

      expect(page).to have_content("Could not issue that token")
    end
  end

  describe "revoking a token" do
    before do
      Lml::ApiToken.issue!(user: @admin, name: "Import script")
      visit "/backstage/api_tokens"
    end

    it "revokes it and says so" do
      accept_confirm { click_on "Revoke" }

      expect(page).to have_content("Token revoked")
      expect(page).to have_css("span", text: "Revoked")
    end
  end
end
