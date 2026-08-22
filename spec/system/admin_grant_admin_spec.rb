# frozen_string_literal: true

require "rails_helper"

# Granting admin is the only way in, so the button has to work in a browser and
# not just as a route. It shipped as `link_to ..., method: :post`, which
# ActiveAdmin 3.5 renders as a plain GET because there is no rails-ujs to read
# it - the request spec passed and the button did nothing.
describe "granting admin access", type: :system do
  before do
    @password = "supersecret123"
    @admin_user = Lml::AdminUser.create!(
      email: "grant_admin_spec@example.com",
      username: "granter",
      password: @password,
      password_confirmation: @password,
      time_zone: "Australia/Melbourne",
    )
    @user = create(:lml_user, email: "punter@example.com")

    sign_in_as_admin
  end

  def sign_in_as_admin
    visit "/admin/login"
    fill_in "admin_user_email", with: @admin_user.email
    fill_in "admin_user_password", with: @password
    find("input[type=submit]").click

    raise "admin sign in failed" unless page.has_no_css?("#admin_user_password")
  end

  it "grants admin from the user page" do
    visit "/admin/users/#{@user.id}"

    click_on "Grant admin access"

    expect(page).to have_content("is now an admin")
    expect(@user.reload.admin?).to be(true)
  end

  it "revokes admin again" do
    @user.update!(admin: true)
    visit "/admin/users/#{@user.id}"

    click_on "Revoke admin access"

    expect(page).to have_content("is no longer an admin")
    expect(@user.reload.admin?).to be(false)
  end

  it "revokes the user's api tokens along with their admin access" do
    @user.update!(admin: true)
    token = Lml::ApiToken.issue!(user: @user, name: "Import script")
    visit "/admin/users/#{@user.id}"

    click_on "Revoke admin access"

    expect(page).to have_content("is no longer an admin")
    expect(token.reload).to be_revoked
  end
end
