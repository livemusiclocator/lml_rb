# frozen_string_literal: true

require "rails_helper"

# A system spec drives a real browser against the real app: it types into the actual form and
# clicks the actual button. That matters for a new field, because a request spec can prove the
# controller accepts `alias_list` while the form is still rendering an input the picker or the
# controller never sees - the element id has to match what ActiveAdmin generates, and nothing but
# a browser checks that. This repo has shipped that exact bug three times; see CLAUDE.md.
#
# The ids come from the model and the attribute: `f.input :alias_list` on an Lml::Act renders
# `id="lml_act_alias_list"`, which is what `fill_in` is finding below.
#
# Run just this file with:
#   bundle exec rspec spec/system/admin_act_aliases_spec.rb
# Add HEADED=1 to watch it happen in a real Chrome window, and SLOWMO=0.5 to slow it down.
describe "an act's aliases in admin", type: :system do
  before do
    @password = "supersecret123"
    @admin_user = Lml::AdminUser.create!(
      email: "act_aliases_spec@example.com",
      username: "aliaser",
      password: @password,
      password_confirmation: @password,
      time_zone: "Australia/Melbourne",
    )

    sign_in_as_admin

    @act = Lml::Act.create!(name: "Amyl and the Sniffers", country: "Australia")
  end

  # Routes are behind subdomain constraints, so spec/support/system.rb points the browser at
  # api.lml.localhost, which is a host Rails can read a subdomain from.
  def sign_in_as_admin
    visit "/admin/login"
    fill_in "admin_user_email", with: @admin_user.email
    fill_in "admin_user_password", with: @password
    find("input[type=submit]").click

    raise "admin sign in failed" unless page.has_no_css?("#admin_user_password")
  end

  it "records aliases typed into the edit form" do
    visit "/admin/acts/#{@act.id}/edit"
    fill_in "lml_act_alias_list", with: "Amyl & the Sniffers, Amyl"
    find("input[type=submit]").click

    # Two assertions, because both halves have to hold: the page reads the value back, and the
    # column really holds the split-up list rather than the one string that was typed.
    expect(page).to have_content("Amyl & the Sniffers, Amyl")
    expect(@act.reload.aliases).to eq(["Amyl & the Sniffers", "Amyl"])
  end

  it "shows the aliases on the act's page" do
    @act.update!(aliases: ["Amyl & the Sniffers"])

    visit "/admin/acts/#{@act.id}"

    expect(page).to have_css("th", text: "Alias List")
    expect(page).to have_content("Amyl & the Sniffers")
  end

  it "lists the aliases beside the name on the index" do
    @act.update!(aliases: ["Amyl & the Sniffers", "Amyl"])

    visit "/admin/acts"

    expect(page).to have_link("Amyl and the Sniffers - (Amyl & the Sniffers, Amyl)")
  end

  # An act with no aliases must not grow an empty bracket on the index.
  it "leaves the name alone for an act with no aliases" do
    visit "/admin/acts"

    expect(page).to have_link("Amyl and the Sniffers")
    expect(page).to have_no_content("Amyl and the Sniffers - (")
  end

  it "clears the aliases when the field is emptied" do
    @act.update!(aliases: ["Amyl"])

    visit "/admin/acts/#{@act.id}/edit"
    fill_in "lml_act_alias_list", with: ""
    find("input[type=submit]").click

    expect(@act.reload.aliases).to eq([])
  end
end
